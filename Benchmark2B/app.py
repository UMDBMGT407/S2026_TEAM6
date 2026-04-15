from flask import Flask, render_template, request, redirect, url_for, abort, jsonify
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_mysqldb import MySQL
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
from datetime import datetime, timedelta
import os
import random
import click

# =======================
# APP CONFIG
# ========================

base_dir = os.path.dirname(os.path.abspath(__file__))

app = Flask(
    __name__,
    template_folder=os.path.join(base_dir, 'templates'),
    static_folder=os.path.join(base_dir, 'static')
)

app.config['SECRET_KEY'] = 'secret-key-change-this'

# --- MySQL Config ---
app.config['MYSQL_HOST'] = 'localhost'
app.config['MYSQL_USER'] = 'root'
app.config['MYSQL_PASSWORD'] = 'UMD2025Smith$'
app.config['MYSQL_DB'] = 'user_management'

mysql = MySQL(app)
SCHEMA_PATH = os.path.join(base_dir, 'Planted_Database.sql')

# --- Ensure suppliers table has is_active ---
def ensure_suppliers_table():
    with app.app_context():
        cur = mysql.connection.cursor()
        # Check if table exists
        cur.execute("SHOW TABLES LIKE 'suppliers'")
        if not cur.fetchone():
            # Create the table
            cur.execute("""
                CREATE TABLE suppliers (
                    supplier_id INT PRIMARY KEY AUTO_INCREMENT,
                    supplier_name VARCHAR(255) NOT NULL,
                    phone VARCHAR(30),
                    email VARCHAR(255),
                    address_id INT,
                    total_orders INT DEFAULT 0,
                    last_order_date DATE,
                    status VARCHAR(50) DEFAULT 'Active',
                    is_active BOOLEAN DEFAULT TRUE,
                    FOREIGN KEY (address_id) REFERENCES addresses(address_id)
                )
            """)
        else:
            # Add column if not exists
            try:
                cur.execute("ALTER TABLE suppliers ADD COLUMN is_active BOOLEAN DEFAULT TRUE")
            except:
                pass  # Column exists

            try:
                cur.execute("ALTER TABLE suppliers MODIFY COLUMN status VARCHAR(50) DEFAULT 'Active'")
            except:
                pass
        try:
            cur.execute("UPDATE suppliers SET status = 'Active' WHERE status IS NULL OR TRIM(status) = ''")
        except:
            pass
        mysql.connection.commit()
        cur.close()

ensure_suppliers_table()
def ensure_client_schema():
    with app.app_context():
        cur = mysql.connection.cursor()
        try:
            cur.execute("ALTER TABLE client_locations ADD COLUMN is_active BOOLEAN DEFAULT TRUE")
        except:
            pass
        try:
            cur.execute("ALTER TABLE clients ADD CONSTRAINT uq_clients_contact_user UNIQUE (contact_user_id)")
        except:
            pass
        try:
            cur.execute("UPDATE client_locations SET is_active = TRUE WHERE is_active IS NULL")
        except:
            pass
        mysql.connection.commit()
        cur.close()

ensure_client_schema()


def ensure_services_schema():
    with app.app_context():
        cur = mysql.connection.cursor()
        try:
            cur.execute("ALTER TABLE services ADD COLUMN is_active BOOLEAN DEFAULT TRUE")
        except:
            pass
        try:
            cur.execute("UPDATE services SET is_active = TRUE WHERE is_active IS NULL")
        except:
            pass
        mysql.connection.commit()
        cur.close()


ensure_services_schema()


def ensure_inventory_schema():
    with app.app_context():
        cur = mysql.connection.cursor()
        try:
            cur.execute("ALTER TABLE inventory_items ADD COLUMN is_active BOOLEAN DEFAULT TRUE")
        except:
            pass
        try:
            cur.execute("UPDATE inventory_items SET is_active = TRUE WHERE is_active IS NULL")
        except:
            pass
        mysql.connection.commit()
        cur.close()


ensure_inventory_schema()


def ensure_material_request_schema():
    with app.app_context():
        cur = mysql.connection.cursor()
        try:
            cur.execute("ALTER TABLE material_request_items MODIFY COLUMN item_id INT NULL")
        except:
            pass
        try:
            cur.execute("ALTER TABLE material_request_items ADD COLUMN requested_item_name VARCHAR(255)")
        except:
            pass
        try:
            cur.execute("ALTER TABLE material_request_items ADD COLUMN requested_unit_label VARCHAR(50)")
        except:
            pass
        try:
            cur.execute("""
                UPDATE material_request_items mri
                JOIN inventory_items ii ON ii.item_id = mri.item_id
                SET mri.requested_item_name = COALESCE(mri.requested_item_name, ii.item_name),
                    mri.requested_unit_label = COALESCE(mri.requested_unit_label, ii.unit_label, 'units')
                WHERE mri.requested_item_name IS NULL
                   OR mri.requested_unit_label IS NULL
            """)
        except:
            pass
        try:
            cur.execute("""
                UPDATE material_request_items
                SET requested_unit_label = 'units'
                WHERE requested_unit_label IS NULL OR TRIM(requested_unit_label) = ''
            """)
        except:
            pass
        mysql.connection.commit()
        cur.close()


ensure_material_request_schema()

# --- Login Manager ---
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'


@login_manager.unauthorized_handler
def handle_unauthorized():
    if request.path.startswith('/api/') or request.path.startswith('/availability'):
        return jsonify(error="Unauthorized - please log in"), 401
    return redirect(url_for('login'))

# ========================
# USER CLASS
# ========================

class User(UserMixin):
    def __init__(self, id, name, email, password, role):
        self.id = id
        self.name = name
        self.email = email
        self.password = password
        self.role = role


@login_manager.user_loader
def load_user(user_id):
    cur = mysql.connection.cursor()
    cur.execute(
        """
        SELECT user_id,
               CONCAT(first_name, ' ', last_name) AS name,
               email,
               password,
               role
        FROM users
        WHERE user_id = %s
        """,
        (user_id,)
    )
    user_data = cur.fetchone()
    cur.close()

    if user_data:
        return User(*user_data)
    return None

# ========================
# ROLE HELPERS
# ========================

def is_admin():
    return current_user.role == 'Management'


def redirect_for_role(role):
    if role == 'Management':
        return redirect(url_for('management_dashboard'))
    if role == 'Staff':
        return redirect(url_for('staff_scheduling_dashboard_page'))
    return redirect(url_for('client_overview_page'))


def role_required(*roles):
    def wrapper(fn):
        @wraps(fn)
        def decorated_view(*args, **kwargs):
            if not current_user.is_authenticated:
                # Return JSON for API requests, HTML abort for regular requests
                if request.path.startswith('/availability') or request.path.startswith('/api/'):
                    return jsonify(error="Unauthorized - not logged in"), 401
                return redirect(url_for('login'))
            
            # Check if user has required role (Management is admin and can access everything)
            user_role = current_user.role if hasattr(current_user, 'role') else None
            is_management = user_role == 'Management'
            has_required_role = user_role in roles
            
            if not (is_management or has_required_role):
                # Return JSON for API requests, HTML abort for regular requests
                if request.path.startswith('/availability') or request.path.startswith('/api/'):
                    return jsonify(error=f"Forbidden: {user_role} role cannot access this"), 403
                return redirect_for_role(user_role)
            
            return fn(*args, **kwargs)
        return decorated_view
    return wrapper


# Custom login_required for API endpoints that returns JSON
def api_login_required(fn):
    @wraps(fn)
    def decorated_view(*args, **kwargs):
        if not current_user.is_authenticated:
            return jsonify(error="Unauthorized - please log in"), 401
        return fn(*args, **kwargs)
    return decorated_view


def require_staff_portal_access():
    role = getattr(current_user, 'role', None)
    if role not in ('Staff', 'Management'):
        return jsonify(error='Forbidden: Staff portal access required'), 403
    return None


def ensure_client_record(cur, user_id, company_name=None):
    cur.execute(
        """
        SELECT client_id FROM clients WHERE contact_user_id = %s LIMIT 1
        """,
        (user_id,)
    )
    existing = cur.fetchone()
    if existing:
        return existing[0]
    
    if not company_name:
        cur.execute(
            """
            SELECT CONCAT(first_name, ' ', last_name) FROM users WHERE user_id = %s
            """,
            (user_id,)
        )
        name_row = cur.fetchone()
        company_name = name_row[0] if name_row and name_row[0] else f"Client {user_id}"

    cur.execute(
        """
        INSERT INTO clients (contact_user_id, company_name, member_since, account_status)
        VALUES (%s, %s, NOW(), %s)
        """,
        (user_id, company_name, 'Active')
    )
    return cur.lastrowid


def generate_job_order_code(cur):
    """Generate a collision-safe job order code."""
    while True:
        code = f"JO-{datetime.utcnow().strftime('%Y%m%d')}-{random.randint(10000, 99999)}"
        cur.execute(
            "SELECT 1 FROM job_orders WHERE job_order_code = %s LIMIT 1",
            (code,)
        )
        if not cur.fetchone():
            return code


def parse_iso_date(value):
    if not value:
        return None
    if hasattr(value, 'year') and hasattr(value, 'month') and hasattr(value, 'day'):
        return value
    try:
        return datetime.strptime(str(value), '%Y-%m-%d').date()
    except Exception:
        return None


def parse_time_value(value):
    if not value:
        return None
    if hasattr(value, 'hour') and hasattr(value, 'minute'):
        return value
    text = str(value).strip()
    for fmt in ('%H:%M', '%H:%M:%S'):
        try:
            return datetime.strptime(text, fmt).time()
        except Exception:
            continue
    return None


def format_time_hhmm(value):
    if not value:
        return None
    if hasattr(value, 'strftime'):
        return value.strftime('%H:%M')
    parsed = parse_time_value(value)
    return parsed.strftime('%H:%M') if parsed else None


def weekday_to_db_day_of_week(target_date):
    # Python: Monday=0..Sunday=6 -> DB: Sunday=0, Monday=1..Saturday=6
    return (target_date.weekday() + 1) % 7


def normalize_job_status(status):
    return str(status or '').strip().lower()


def check_employee_assignment_eligibility(cur, employee_id, scheduled_date, start_time, end_time, exclude_job_id=None):
    """
    Validate if an employee can be assigned for a specific date/time.
    Rules:
    1) Employee must be active Staff.
    2) Employee availability must include the full requested window.
    3) Employee must not have an overlapping non-completed/non-cancelled job.
    """
    result = {
        'is_available': False,
        'reason': None,
        'employee_id': employee_id,
        'employee_name': None,
        'availability_from': None,
        'availability_to': None,
        'conflict_job_id': None,
        'conflict_job_title': None
    }

    parsed_date = parse_iso_date(scheduled_date)
    parsed_start = parse_time_value(start_time)
    parsed_end = parse_time_value(end_time)

    if not parsed_date:
        result['reason'] = 'scheduled_date is required and must be YYYY-MM-DD'
        return result
    if not parsed_start or not parsed_end:
        result['reason'] = 'start_time and end_time are required and must be HH:MM'
        return result
    if parsed_end <= parsed_start:
        result['reason'] = 'end_time must be later than start_time'
        return result

    cur.execute(
        """
        SELECT e.employee_id,
               CONCAT(u.first_name, ' ', u.last_name) AS employee_name
        FROM employees e
        JOIN users u ON u.user_id = e.user_id
        WHERE e.employee_id = %s
          AND u.role = 'Staff'
          AND u.is_active = TRUE
        LIMIT 1
        """,
        (employee_id,)
    )
    employee_row = cur.fetchone()
    if not employee_row:
        result['reason'] = 'Employee not found or not active Staff'
        return result
    result['employee_name'] = employee_row[1]

    week_start = parsed_date - timedelta(days=parsed_date.weekday())
    db_day = weekday_to_db_day_of_week(parsed_date)
    cur.execute(
        """
        SELECT available_from,
               available_to,
               COALESCE(is_available, TRUE) AS is_available
        FROM employee_availability
        WHERE employee_id = %s
          AND week_start_date = %s
          AND day_of_week = %s
        LIMIT 1
        """,
        (employee_id, week_start, db_day)
    )
    availability_row = cur.fetchone()
    if not availability_row:
        # Fallback to the most recently saved week for this weekday.
        cur.execute(
            """
            SELECT available_from,
                   available_to,
                   COALESCE(is_available, TRUE) AS is_available
            FROM employee_availability
            WHERE employee_id = %s
              AND day_of_week = %s
            ORDER BY week_start_date DESC
            LIMIT 1
            """,
            (employee_id, db_day)
        )
        availability_row = cur.fetchone()
    if not availability_row:
        result['reason'] = 'Employee has no availability set for that date'
        return result

    available_from = parse_time_value(availability_row[0])
    available_to = parse_time_value(availability_row[1])
    is_available_flag = bool(availability_row[2]) if availability_row[2] is not None else False

    result['availability_from'] = format_time_hhmm(available_from)
    result['availability_to'] = format_time_hhmm(available_to)

    if not is_available_flag or not available_from or not available_to:
        result['reason'] = 'Employee is marked unavailable for that date'
        return result

    if parsed_start < available_from or parsed_end > available_to:
        result['reason'] = (
            f"Employee availability is {format_time_hhmm(available_from)}-{format_time_hhmm(available_to)}"
        )
        return result

    conflict_sql = """
        SELECT jo.job_order_id,
               jo.title
        FROM job_orders jo
        WHERE jo.assigned_employee_id = %s
          AND jo.scheduled_date = %s
          AND jo.start_time IS NOT NULL
          AND jo.end_time IS NOT NULL
          AND LOWER(COALESCE(jo.status, '')) NOT IN ('completed', 'cancelled', 'canceled')
          AND (%s < jo.end_time AND %s > jo.start_time)
    """
    conflict_params = [employee_id, parsed_date, parsed_start, parsed_end]
    if exclude_job_id is not None:
        conflict_sql += " AND jo.job_order_id <> %s"
        conflict_params.append(exclude_job_id)
    conflict_sql += " ORDER BY jo.start_time LIMIT 1"

    cur.execute(conflict_sql, tuple(conflict_params))
    conflict_row = cur.fetchone()
    if conflict_row:
        result['conflict_job_id'] = conflict_row[0]
        result['conflict_job_title'] = conflict_row[1] or 'Existing job'
        result['reason'] = f"Employee already has overlapping job #{conflict_row[0]}"
        return result

    result['is_available'] = True
    result['reason'] = None
    return result


def list_available_employees_for_window(cur, scheduled_date, start_time, end_time, exclude_job_id=None):
    cur.execute(
        """
        SELECT e.employee_id,
               u.user_id,
               CONCAT(u.first_name, ' ', u.last_name) AS employee_name,
               u.email,
               u.phone,
               e.job_title
        FROM employees e
        JOIN users u ON u.user_id = e.user_id
        WHERE u.role = 'Staff'
          AND u.is_active = TRUE
        ORDER BY u.first_name, u.last_name
        """
    )
    rows = cur.fetchall()

    available = []
    unavailable = []
    for row in rows:
        employee_id = row[0]
        eligibility = check_employee_assignment_eligibility(
            cur,
            employee_id,
            scheduled_date,
            start_time,
            end_time,
            exclude_job_id=exclude_job_id
        )
        employee_payload = {
            'employee_id': employee_id,
            'user_id': row[1],
            'name': row[2] or '',
            'email': row[3] or '',
            'phone': row[4] or '',
            'job_title': row[5] or '',
            'availability_from': eligibility.get('availability_from'),
            'availability_to': eligibility.get('availability_to'),
            'reason': eligibility.get('reason')
        }
        if eligibility.get('is_available'):
            available.append(employee_payload)
        else:
            unavailable.append(employee_payload)

    return available, unavailable

# --- Login Page ---
@app.route('/')
def root():
    return redirect(url_for('login'))


@app.route('/LoginPortal', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        email = request.form.get('email', '').strip().lower()
        password = request.form.get('password', '')

        cur = mysql.connection.cursor()
        cur.execute(
            """
            SELECT user_id,
                   CONCAT(first_name, ' ', last_name) AS name,
                   email,
                   password,
                   role
            FROM users
            WHERE LOWER(TRIM(email)) = %s AND is_active = TRUE
            """,
            (email,)
        )
        user_data = cur.fetchone()
        cur.close()

        if user_data and check_password_hash(user_data[3], password):
            user = User(*user_data)
            login_user(user)

            # ROLE-BASED REDIRECT
            if user.role == 'Management':
                return redirect(url_for('management_dashboard'))
            if user.role == 'Staff':
                return redirect(url_for('staff_scheduling_dashboard_page'))
            else:
                return redirect(url_for('client_dashboard'))

        return render_template('LoginPortal.html', error="Invalid credentials")

    return render_template('LoginPortal.html')


@app.route('/CreateAccount')
def create_account():
    return render_template('CreateAccount.html')


@app.route('/CreateAccount', methods=['POST'])
def create_account_post():
    full_name = request.form.get('name', '').strip()
    email = request.form.get('email', '').strip()
    password = request.form.get('password', '')
    confirm_password = request.form.get('confirm-password', '')

    if not full_name or not email or not password:
        return render_template('CreateAccount.html', error="All fields are required")

    if password != confirm_password:
        return render_template('CreateAccount.html', error="Passwords do not match")

    name_parts = full_name.split(None, 1)
    first_name = name_parts[0]
    last_name = name_parts[1] if len(name_parts) > 1 else 'User'

    cur = mysql.connection.cursor()
    cur.execute("SELECT user_id FROM users WHERE email = %s", (email,))
    existing_user = cur.fetchone()

    if existing_user:
        cur.close()
        return render_template('CreateAccount.html', error="An account with that email already exists")

    hashed_password = generate_password_hash(password)
    cur.execute(
        """
        INSERT INTO users (role, email, password, first_name, last_name, is_active)
        VALUES (%s, %s, %s, %s, %s, TRUE)
        """,
        ('Client', email, hashed_password, first_name, last_name)
    )

    user_id = cur.lastrowid
    user_name = f"{first_name} {last_name}"

    # Auto-create client profiles for downstream workflows.
    cur.execute(
        """
        INSERT INTO clients (contact_user_id, company_name, member_since, account_status)
        VALUES (%s, %s, NOW(), %s)
        """,
        (user_id, user_name, 'Active')
    )

    mysql.connection.commit()
    cur.close()

    login_user(User(user_id, user_name, email, hashed_password, 'Client'))
    return redirect(url_for('client_dashboard'))


@app.route('/LoginPortalForgotPassword')
def forgot_password():
    return render_template('LoginPortalForgotPassword.html')


@app.route('/LoginPortalForgotPassword', methods=['POST'])
def forgot_password_post():
    email = request.form.get('email', '').strip()
    confirm_email = request.form.get('confirm-email', '').strip()

    if not email or email != confirm_email:
        return render_template('LoginPortalForgotPassword.html', error="Email addresses must match")

    return redirect(url_for('emailed_password_reset', email=email))


@app.route('/EmailedPasswordReset')
def emailed_password_reset():
    return render_template('EmailedPasswordReset.html')


@app.route('/db-check')
def db_check():
    cur = mysql.connection.cursor()
    cur.execute(
        """
        SELECT user_id, email, role, is_active
        FROM users
        ORDER BY user_id
        LIMIT 10
        """
    )
    users = cur.fetchall()
    cur.close()

    return jsonify(
        connected=True,
        user_count=len(users),
        users=[
            {
                'user_id': row[0],
                'email': row[1],
                'role': row[2],
                'is_active': bool(row[3]),
            }
            for row in users
        ],
    )


# --- Logout ---
@app.route('/logout')
@login_required
def logout():
    logout_user()
    return redirect(url_for('login'))


# ========================
# DASHBOARDS
# ========================

# --- Management Portal (Admin) ---
@app.route('/management')
@login_required
@role_required('Management')
def management_dashboard():
    return render_template('manage-employee.html')


# --- Client Portal (User) ---
@app.route('/client')
@login_required
@role_required('Client')
def client_dashboard():
    return redirect(url_for('client_overview_page'))


@app.route('/client/overview')
@login_required
@role_required('Client')
def client_overview_page():
    return render_template('clientindex.html')


@app.route('/index.html')
@login_required
def index_page():
    if current_user.role == 'Management':
        return redirect(url_for('management_dashboard'))
    if current_user.role == 'Staff':
        return redirect(url_for('staff_scheduling_dashboard_page'))
    return redirect(url_for('client_overview_page'))


@app.route('/appointments.html')
@login_required
@role_required('Client')
def appointments_page():
    return render_template('appointments.html')


@app.route('/service-request.html')
@login_required
@role_required('Client')
def service_request_page():
    return render_template('service-request.html')


@app.route('/invoices.html')
@login_required
@role_required('Client')
def invoices_page():
    return render_template('invoices.html')


@app.route('/profile.html')
@login_required
def profile_page():
    return render_template('profile.html')


@app.route('/clients.html')
@login_required
@role_required('Management')
def clients_page():
    return render_template('clients.html')


@app.route('/scheduling.html')
@login_required
@role_required('Management')
def scheduling_page():
    return render_template('scheduling.html')


@app.route('/suppliers.html')
@login_required
@role_required('Management')
def suppliers_page():
    return render_template('suppliers.html')


@app.route('/inventory.html')
@login_required
@role_required('Management')
def inventory_page():
    return render_template('inventory.html')


@app.route('/api/inventory', methods=['GET'])
@login_required
@role_required('Management')
def get_inventory():
    search = request.args.get('search', '').strip()
    cur = mysql.connection.cursor()
    sql = """
        SELECT i.item_id, i.item_name, i.item_type, i.sku,
               i.unit_price, i.quantity_on_hand, i.reorder_level,
               i.unit_label, COALESCE(i.is_active, TRUE) AS is_active,
               s.supplier_name, s.supplier_id
        FROM inventory_items i
        LEFT JOIN suppliers s ON s.supplier_id = i.supplier_id
        WHERE COALESCE(i.is_active, TRUE) = TRUE
    """
    params = []
    if search:
        sql += " AND i.item_name LIKE %s"
        params.append(f'%{search}%')
    sql += " ORDER BY i.item_name"
    cur.execute(sql, tuple(params))
    rows = cur.fetchall()
    cur.close()
    return jsonify([{
        'item_id': r[0],
        'item_name': r[1],
        'item_type': r[2],
        'sku': r[3],
        'unit_price': float(r[4]) if r[4] is not None else None,
        'quantity_on_hand': float(r[5]) if r[5] is not None else 0,
        'reorder_level': float(r[6]) if r[6] is not None else 0,
        'unit_label': r[7] or 'units',
        'is_active': bool(r[8]),
        'supplier_name': r[9],
        'supplier_id': r[10],
    } for r in rows])


@app.route('/api/inventory', methods=['POST'])
@login_required
@role_required('Management')
def add_inventory_item():
    data = request.get_json() or {}
    item_name = (data.get('item_name') or '').strip()
    if not item_name:
        return jsonify(error='Item name is required'), 400
    cur = mysql.connection.cursor()
    cur.execute("""
        INSERT INTO inventory_items
            (item_name, item_type, supplier_id, sku, unit_price,
             quantity_on_hand, reorder_level, unit_label, is_active)
        VALUES (%s, %s, %s, %s, %s, %s, %s, %s, TRUE)
    """, (
        item_name,
        data.get('item_type') or None,
        data.get('supplier_id') or None,
        data.get('sku') or None,
        data.get('unit_price') or None,
        data.get('quantity_on_hand') or 0,
        data.get('reorder_level') or 0,
        data.get('unit_label') or 'units',
    ))
    mysql.connection.commit()
    cur.close()
    return jsonify(message='Item added successfully'), 201


@app.route('/api/inventory/<int:item_id>/stock', methods=['PATCH'])
@login_required
@role_required('Management')
def adjust_inventory_stock(item_id):
    data = request.get_json() or {}
    qty = data.get('quantity_on_hand')
    if qty is None or float(qty) < 0:
        return jsonify(error='Valid quantity required'), 400
    cur = mysql.connection.cursor()
    cur.execute("UPDATE inventory_items SET quantity_on_hand = %s WHERE item_id = %s", (float(qty), item_id))
    mysql.connection.commit()
    cur.close()
    return jsonify(message='Stock updated')


@app.route('/api/inventory/<int:item_id>/reorder', methods=['POST'])
@login_required
@role_required('Management')
def reorder_inventory_item(item_id):
    cur = mysql.connection.cursor()
    cur.execute("SELECT reorder_level FROM inventory_items WHERE item_id = %s", (item_id,))
    row = cur.fetchone()
    if not row:
        cur.close()
        return jsonify(error='Item not found'), 404
    reorder_level = float(row[0]) if row[0] else 0
    new_qty = reorder_level + 20
    cur.execute("UPDATE inventory_items SET quantity_on_hand = %s WHERE item_id = %s", (new_qty, item_id))
    mysql.connection.commit()
    cur.close()
    return jsonify(message='Reorder placed', new_quantity=new_qty)


@app.route('/staff/inventory/options', methods=['GET'])
@api_login_required
def staff_inventory_item_options():
    access_error = require_staff_portal_access()
    if access_error:
        return access_error
    try:
        search = (request.args.get('search') or '').strip()
        cur = mysql.connection.cursor()
        sql = """
            SELECT item_id,
                   item_name,
                   item_type,
                   unit_price,
                   COALESCE(unit_label, 'units') AS unit_label,
                   quantity_on_hand,
                   reorder_level
            FROM inventory_items
            WHERE COALESCE(is_active, TRUE) = TRUE
        """
        params = []
        if search:
            sql += " AND item_name LIKE %s"
            params.append(f'%{search}%')
        sql += " ORDER BY item_name LIMIT 200"
        cur.execute(sql, tuple(params))
        rows = cur.fetchall()
        cur.close()

        options = []
        for row in rows:
            options.append({
                'item_id': row[0],
                'item_name': row[1] or '',
                'item_type': row[2] or '',
                'unit_price': float(row[3]) if row[3] is not None else None,
                'unit_label': row[4] or 'units',
                'quantity_on_hand': float(row[5]) if row[5] is not None else 0,
                'reorder_level': float(row[6]) if row[6] is not None else 0,
            })

        return jsonify(items=options)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load inventory options: {str(e)}'), 500


@app.route('/api/management/material-requests', methods=['GET'])
@login_required
@role_required('Management')
def get_management_material_requests():
    status = (request.args.get('status') or 'pending').strip().lower()
    search = (request.args.get('search') or '').strip()
    limit_raw = (request.args.get('limit') or '50').strip()

    try:
        limit = int(limit_raw)
    except Exception:
        return jsonify(error='limit must be an integer'), 400
    if limit < 1 or limit > 250:
        return jsonify(error='limit must be between 1 and 250'), 400

    status_filter = {
        'pending': 'pending',
        'approved': 'approved',
        'rejected': 'rejected',
    }
    if status != 'all' and status not in status_filter:
        return jsonify(error='status must be one of: pending, approved, rejected, all'), 400

    base_sql = """
        SELECT mr.material_request_id,
               mr.request_code,
               mr.status,
               mr.note,
               mr.created_at,
               mr.task_id,
               t.task_name,
               e.employee_id,
               CONCAT(u.first_name, ' ', u.last_name) AS employee_name
        FROM material_requests mr
        JOIN employees e ON e.employee_id = mr.employee_id
        JOIN users u ON u.user_id = e.user_id
        LEFT JOIN tasks t ON t.task_id = mr.task_id
    """

    where_clauses = []
    params = []

    if status != 'all':
        where_clauses.append("LOWER(COALESCE(mr.status, 'Pending')) = %s")
        params.append(status_filter[status])

    if search:
        where_clauses.append("""
            (
                mr.request_code LIKE %s
                OR CONCAT(u.first_name, ' ', u.last_name) LIKE %s
                OR COALESCE(t.task_name, '') LIKE %s
                OR COALESCE(mr.note, '') LIKE %s
            )
        """)
        like_search = f'%{search}%'
        params.extend([like_search, like_search, like_search, like_search])

    if where_clauses:
        base_sql += " WHERE " + " AND ".join(where_clauses)

    base_sql += " ORDER BY mr.created_at DESC, mr.material_request_id DESC LIMIT %s"
    params.append(limit)

    try:
        cur = mysql.connection.cursor()
        cur.execute(base_sql, tuple(params))
        request_rows = cur.fetchall()

        requests_out = []
        for row in request_rows:
            request_id = row[0]
            cur.execute(
                """
                SELECT mri.material_request_item_id,
                       mri.item_id,
                       ii.item_name,
                       mri.requested_item_name,
                       mri.quantity_requested,
                       COALESCE(ii.unit_label, mri.requested_unit_label, 'units') AS unit_label,
                       COALESCE(ii.is_active, TRUE) AS inventory_is_active
                FROM material_request_items mri
                LEFT JOIN inventory_items ii ON ii.item_id = mri.item_id
                WHERE mri.material_request_id = %s
                ORDER BY mri.material_request_item_id
                """,
                (request_id,)
            )
            item_rows = cur.fetchall()
            items = []
            has_unlinked_items = False
            for irow in item_rows:
                item_id = irow[1]
                item_name = irow[2] or irow[3] or ''
                is_linked = bool(item_id) and bool(irow[6])
                if not is_linked:
                    has_unlinked_items = True
                items.append({
                    'material_request_item_id': irow[0],
                    'item_id': item_id,
                    'item_name': item_name,
                    'requested_item_name': irow[3] or item_name,
                    'quantity_requested': float(irow[4]) if irow[4] is not None else 0,
                    'unit_label': irow[5] or 'units',
                    'linked_to_inventory': is_linked
                })

            if not items:
                has_unlinked_items = True

            requests_out.append({
                'material_request_id': request_id,
                'request_code': row[1] or '',
                'status': row[2] or 'Pending',
                'note': row[3] or '',
                'created_at': row[4].isoformat() if row[4] else None,
                'task_id': row[5],
                'task_name': row[6] or '',
                'employee_id': row[7],
                'employee_name': row[8] or '',
                'items': items,
                'has_unlinked_items': has_unlinked_items
            })

        cur.close()
        return jsonify(requests=requests_out)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load material requests: {str(e)}'), 500


def build_material_request_decision_note(existing_note, decision, manager_note=''):
    timestamp = datetime.now().strftime('%Y-%m-%d %H:%M')
    audit_note = f"[Management {decision} on {timestamp} by user {current_user.id}]"
    manager_note = manager_note.strip()
    if manager_note:
        audit_note = f"{audit_note} {manager_note}"

    existing_note = (existing_note or '').strip()
    if not existing_note:
        return audit_note
    return f"{existing_note}\n{audit_note}"


def autolink_material_request_items(cur, material_request_id):
    cur.execute(
        """
        SELECT material_request_item_id,
               requested_item_name
        FROM material_request_items
        WHERE material_request_id = %s
          AND item_id IS NULL
        """,
        (material_request_id,)
    )
    unresolved_rows = cur.fetchall()

    for row in unresolved_rows:
        request_item_id = row[0]
        requested_name = (row[1] or '').strip()
        if not requested_name:
            continue

        cur.execute(
            """
            SELECT item_id
            FROM inventory_items
            WHERE COALESCE(is_active, TRUE) = TRUE
              AND LOWER(TRIM(item_name)) = LOWER(TRIM(%s))
            LIMIT 1
            """,
            (requested_name,)
        )
        match = cur.fetchone()
        if match:
            cur.execute(
                """
                UPDATE material_request_items
                SET item_id = %s
                WHERE material_request_item_id = %s
                """,
                (match[0], request_item_id)
            )


def list_unlinked_material_request_items(cur, material_request_id):
    cur.execute(
        """
        SELECT mri.material_request_item_id,
               mri.item_id,
               COALESCE(ii.item_name, mri.requested_item_name, '') AS display_name,
               COALESCE(ii.is_active, TRUE) AS inventory_is_active
        FROM material_request_items mri
        LEFT JOIN inventory_items ii ON ii.item_id = mri.item_id
        WHERE mri.material_request_id = %s
        ORDER BY mri.material_request_item_id
        """,
        (material_request_id,)
    )
    rows = cur.fetchall()
    if not rows:
        return ['No material line items are linked to this request yet']

    unresolved = []
    for row in rows:
        item_id = row[1]
        item_name = (row[2] or '').strip() or f'Line item #{row[0]}'
        is_active = bool(row[3])
        if not item_id:
            unresolved.append(item_name)
            continue
        if not is_active:
            unresolved.append(f'{item_name} (inactive)')
    return unresolved


@app.route('/api/management/material-requests/<int:material_request_id>/approve', methods=['POST'])
@login_required
@role_required('Management')
def approve_material_request(material_request_id):
    payload = request.get_json(silent=True) or {}
    manager_note = (payload.get('note') or '').strip()

    try:
        cur = mysql.connection.cursor()
        cur.execute(
            """
            SELECT status,
                   note
            FROM material_requests
            WHERE material_request_id = %s
            """,
            (material_request_id,)
        )
        row = cur.fetchone()
        if not row:
            cur.close()
            return jsonify(error='Material request not found'), 404

        current_status = (row[0] or 'Pending').strip().lower()
        if current_status in ('approved', 'rejected'):
            cur.close()
            return jsonify(error=f'Material request is already {row[0] or "processed"}'), 400

        # Approval rule: every requested line item must be tied to active inventory.
        autolink_material_request_items(cur, material_request_id)
        unresolved_items = list_unlinked_material_request_items(cur, material_request_id)
        if unresolved_items:
            mysql.connection.commit()
            cur.close()
            return jsonify(
                error=(
                    'Request cannot be approved until every material is mapped to active inventory. '
                    'Unresolved: ' + ', '.join(unresolved_items)
                )
            ), 400

        merged_note = build_material_request_decision_note(row[1], 'Approved', manager_note)
        cur.execute(
            """
            UPDATE material_requests
            SET status = %s,
                note = %s
            WHERE material_request_id = %s
            """,
            ('Approved', merged_note, material_request_id)
        )
        mysql.connection.commit()
        cur.close()
        return jsonify(message='Material request approved', material_request_id=material_request_id)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        mysql.connection.rollback()
        return jsonify(error=f'Failed to approve material request: {str(e)}'), 500


@app.route('/api/management/material-requests/<int:material_request_id>/reject', methods=['POST'])
@login_required
@role_required('Management')
def reject_material_request(material_request_id):
    payload = request.get_json(silent=True) or {}
    manager_note = (payload.get('note') or '').strip()

    try:
        cur = mysql.connection.cursor()
        cur.execute(
            """
            SELECT status,
                   note
            FROM material_requests
            WHERE material_request_id = %s
            """,
            (material_request_id,)
        )
        row = cur.fetchone()
        if not row:
            cur.close()
            return jsonify(error='Material request not found'), 404

        current_status = (row[0] or 'Pending').strip().lower()
        if current_status in ('approved', 'rejected'):
            cur.close()
            return jsonify(error=f'Material request is already {row[0] or "processed"}'), 400

        merged_note = build_material_request_decision_note(row[1], 'Rejected', manager_note)
        cur.execute(
            """
            UPDATE material_requests
            SET status = %s,
                note = %s
            WHERE material_request_id = %s
            """,
            ('Rejected', merged_note, material_request_id)
        )
        mysql.connection.commit()
        cur.close()
        return jsonify(message='Material request rejected', material_request_id=material_request_id)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        mysql.connection.rollback()
        return jsonify(error=f'Failed to reject material request: {str(e)}'), 500


@app.route('/api/management/material-usage', methods=['GET'])
@login_required
@role_required('Management')
def get_management_material_usage():
    search = (request.args.get('search') or '').strip()
    limit_raw = (request.args.get('limit') or '50').strip()

    try:
        limit = int(limit_raw)
    except Exception:
        return jsonify(error='limit must be an integer'), 400
    if limit < 1 or limit > 250:
        return jsonify(error='limit must be between 1 and 250'), 400

    base_sql = """
        SELECT mul.usage_log_id,
               mul.logged_at,
               mul.task_id,
               t.task_name,
               e.employee_id,
               CONCAT(u.first_name, ' ', u.last_name) AS employee_name
        FROM material_usage_logs mul
        JOIN tasks t ON t.task_id = mul.task_id
        JOIN employees e ON e.employee_id = mul.employee_id
        JOIN users u ON u.user_id = e.user_id
    """
    params = []
    if search:
        base_sql += """
            WHERE (
                CONCAT(u.first_name, ' ', u.last_name) LIKE %s
                OR COALESCE(t.task_name, '') LIKE %s
            )
        """
        like_search = f'%{search}%'
        params.extend([like_search, like_search])
    base_sql += " ORDER BY mul.logged_at DESC, mul.usage_log_id DESC LIMIT %s"
    params.append(limit)

    try:
        cur = mysql.connection.cursor()
        cur.execute(base_sql, tuple(params))
        usage_rows = cur.fetchall()
        logs = []

        for row in usage_rows:
            usage_log_id = row[0]
            cur.execute(
                """
                SELECT mui.item_id,
                       ii.item_name,
                       mui.quantity_used,
                       COALESCE(ii.unit_label, 'units') AS unit_label
                FROM material_usage_items mui
                JOIN inventory_items ii ON ii.item_id = mui.item_id
                WHERE mui.usage_log_id = %s
                ORDER BY mui.usage_item_id
                """,
                (usage_log_id,)
            )
            item_rows = cur.fetchall()
            items = [{
                'item_id': irow[0],
                'item_name': irow[1] or '',
                'quantity_used': float(irow[2]) if irow[2] is not None else 0,
                'unit_label': irow[3] or 'units'
            } for irow in item_rows]

            logs.append({
                'usage_log_id': usage_log_id,
                'logged_at': row[1].isoformat() if row[1] else None,
                'task_id': row[2],
                'task_name': row[3] or '',
                'employee_id': row[4],
                'employee_name': row[5] or '',
                'items': items
            })

        cur.close()
        return jsonify(logs=logs)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load material usage logs: {str(e)}'), 500


@app.route('/plant-master.html')
@login_required
@role_required('Management')
def plant_master_page():
    return render_template('plant-master.html')


@app.route('/job-order.html')
@login_required
@role_required('Management')
def job_order_page():
    return render_template('job-order.html')


@app.route('/services.html')
@login_required
@role_required('Management')
def services_page():
    return render_template('services.html')


@app.route('/staff-scheduling-dashboard.html')
@login_required
@role_required('Staff')
def staff_scheduling_dashboard_page():
    return render_template('staff-scheduling-dashboard.html')


@app.route('/task-management-dashboard.html')
@login_required
@role_required('Staff')
def task_management_dashboard_page():
    tasks = []
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT employee_id FROM employees WHERE user_id = %s", (current_user.id,))
        emp_row = cur.fetchone()
        if emp_row:
            employee_id = emp_row[0]
            cur.execute("""
                SELECT t.task_id,
                       t.task_name,
                       t.description,
                       t.status,
                       jo.scheduled_date,
                       jo.start_time,
                       jo.end_time,
                       cl.company_name,
                       CONCAT(u.first_name, ' ', u.last_name) AS contact_name,
                       u.phone AS contact_phone,
                       u.email AS contact_email,
                       CONCAT(a.street_address, ', ', a.city, ', ', a.state, ' ', a.zip_code) AS location
                FROM tasks t
                JOIN job_orders jo ON jo.job_order_id = t.job_order_id
                LEFT JOIN clients cl ON cl.client_id = jo.client_id
                LEFT JOIN users u ON u.user_id = cl.contact_user_id
                LEFT JOIN client_locations cloc ON cloc.location_id = jo.location_id
                LEFT JOIN addresses a ON a.address_id = cloc.address_id
                WHERE t.assigned_employee_id = %s
                ORDER BY jo.scheduled_date DESC, t.task_id DESC
            """, (employee_id,))
            rows = cur.fetchall()
            for r in rows:
                task_id, task_name, description, status, sched_date, start_t, end_t, company, contact_name, contact_phone, contact_email, location = r
                # Build status class/label
                status_map = {
                    'Scheduled': ('staff-status-scheduled', 'Scheduled'),
                    'In Progress': ('staff-status-in-progress', 'In Progress'),
                    'Completed': ('staff-status-complete', 'Completed'),
                    'Cancelled': ('staff-status-cancelled', 'Cancelled'),
                }
                status_class, status_label = status_map.get(status, ('staff-status-incomplete', status or 'Pending'))
                # Build service window string
                if sched_date:
                    if hasattr(sched_date, 'year') and hasattr(sched_date, 'month') and hasattr(sched_date, 'day'):
                        date_str = f"{sched_date.strftime('%B')} {sched_date.day}, {sched_date.year}"
                    else:
                        date_str = str(sched_date)
                    if start_t and end_t:
                        def fmt_time(t):
                            if hasattr(t, 'seconds'):
                                total = int(t.seconds)
                                h, m = divmod(total // 60, 60)
                            else:
                                parts = str(t).split(':')
                                h, m = int(parts[0]), int(parts[1])
                            period = 'AM' if h < 12 else 'PM'
                            h12 = h % 12 or 12
                            return f'{h12}:{m:02d} {period}'
                        service_window = f'{date_str}, {fmt_time(start_t)} - {fmt_time(end_t)}'
                    else:
                        service_window = date_str
                else:
                    service_window = 'TBD'
                # Fetch materials
                cur.execute("""
                    SELECT ii.item_name, tm.required_quantity, ii.unit_label
                    FROM task_materials tm
                    JOIN inventory_items ii ON ii.item_id = tm.item_id
                    WHERE tm.task_id = %s
                """, (task_id,))
                mat_rows = cur.fetchall()
                materials_encoded = '|'.join(
                    f'{m[0]}::{m[1]} {m[2] or "units"}' for m in mat_rows
                )
                tasks.append({
                    'title': task_name or 'Untitled Task',
                    'description': description or '',
                    'status': status or '',
                    'status_class': status_class,
                    'status_label': status_label,
                    'service_window': service_window,
                    'location': location or 'TBD',
                    'client_company': company or 'Unknown Client',
                    'contact_name': contact_name or '',
                    'contact_phone': contact_phone or '',
                    'contact_email': contact_email or '',
                    'contact_location': location or '',
                    'task_context': description or '',
                    'materials_encoded': materials_encoded,
                })
        cur.close()
    except Exception as e:
        print(f'Error loading tasks for dashboard: {e}')
    return render_template('task-management-dashboard.html', tasks=tasks)


@app.route('/inventory-dashboard.html')
@login_required
@role_required('Staff')
def inventory_dashboard_page():
    return render_template('inventory-dashboard.html')


@app.route('/availability-entry.html')
@login_required
@role_required('Staff')
def availability_entry_page():
    return redirect(url_for('staff_scheduling_dashboard_page', modal='availability'))


@app.route('/material-requests.html')
@login_required
@role_required('Staff')
def material_requests_page():
    return redirect(url_for('inventory_dashboard_page', modal='request'))


@app.route('/used-material-log.html')
@login_required
@role_required('Staff')
def used_material_log_page():
    return redirect(url_for('inventory_dashboard_page', modal='usage'))


@app.route('/job-materials.html')
@login_required
@role_required('Staff')
def job_materials_page():
    return redirect(url_for('task_management_dashboard_page', modal='materials'))


@app.route('/contact-client.html')
@login_required
@role_required('Staff')
def contact_client_page():
    return redirect(url_for('task_management_dashboard_page', modal='contact'))


# ========================
# USER MANAGEMENT API
# ========================

# --- Add User (Admin Only) ---
@app.route('/user', methods=['POST'])
@login_required
@role_required('Management')
def add_user():
    if request.is_json:
        data = request.get_json()

        full_name = data.get('name', '').strip()
        first_name = data.get('first_name', '')
        last_name = data.get('last_name', '')

        if full_name and not first_name:
            name_parts = full_name.split(None, 1)
            first_name = name_parts[0]
            last_name = name_parts[1] if len(name_parts) > 1 else ''

        if not first_name or not last_name:
            return jsonify(error="first_name and last_name are required"), 400

        email = data['email']
        role = data.get('role', 'Client')
        password = generate_password_hash(data.get('password', 'test123'))
        phone = data.get('phone')

        cur = mysql.connection.cursor()

        sql = """
            INSERT INTO users (first_name, last_name, email, password, role, phone, is_active)
            VALUES (%s, %s, %s, %s, %s, %s, TRUE)
        """
        cur.execute(sql, (first_name, last_name, email, password, role, phone))
        
        # Get the newly created user_id
        user_id = cur.lastrowid
        
        # If this is a Staff user, automatically create an employee record
        if role == 'Staff':
            employee_code = 'EMP{:03d}'.format(user_id)  # Generate code like EMP001, EMP002, etc.
            cur.execute(
                """
                INSERT INTO employees (user_id, employee_code, job_title)
                VALUES (%s, %s, %s)
                """,
                (user_id, employee_code, 'Staff')
            )
        elif role == 'Client':
            default_company_name = f"{first_name} {last_name}"
            cur.execute(
                """
                INSERT INTO clients (contact_user_id, company_name, member_since, account_status)
                VALUES (%s, %s, NOW(), %s)
                """,
                (user_id, default_company_name, 'Active')
            )
            
        mysql.connection.commit()
        cur.close()

        return jsonify(message="User added successfully"), 201

    return jsonify(error="Invalid submission"), 400


# --- View Users ---
@app.route('/users', methods=['GET'])
@login_required
def get_users():
    cur = mysql.connection.cursor()

    cur.execute(
        """
        SELECT user_id,
               CONCAT(first_name, ' ', last_name) AS name,
               email,
               role,
               is_active
        FROM users
        ORDER BY user_id
        """
    )
    users = cur.fetchall()

    cur.close()

    user_dicts = []

    for user in users:
        user_data = {
            'id': user[0],
            'name': user[1],
            'role': user[3],
            'is_active': bool(user[4])
        }

        if is_admin():
            user_data['email'] = user[2]

        user_dicts.append(user_data)

    return jsonify(user_dicts)


# --- Delete User ---
@app.route('/user/<int:id>', methods=['DELETE'])
@login_required
@role_required('Management')
def delete_user(id):
    cur = mysql.connection.cursor()

    # Soft-delete: mark the user inactive instead of deleting the row
    cur.execute("UPDATE users SET is_active = FALSE WHERE user_id = %s", (id,))

    mysql.connection.commit()
    cur.close()

    return jsonify(message="User marked inactive successfully")


@app.route('/user/<int:id>/reactivate', methods=['POST'])
@login_required
@role_required('Management')
def reactivate_user(id):
    cur = mysql.connection.cursor()

    # Reactivate the user account
    cur.execute("UPDATE users SET is_active = TRUE WHERE user_id = %s", (id,))

    mysql.connection.commit()
    cur.close()

    return jsonify(message="User reactivated successfully")


# --- Get Employees (Staff only) ---
@app.route('/employees', methods=['GET'])
@login_required
@role_required('Management')
def get_employees():
    cur = mysql.connection.cursor()
    # Optional filters
    search = request.args.get('search', '').strip()
    status = request.args.get('status', 'active').strip().lower()
    if status not in ('active', 'inactive', 'all'):
        status = 'active'

    base_sql = """
     SELECT u.user_id,
         CONCAT(u.first_name, ' ', u.last_name) AS name,
         u.email,
         u.is_active,
         u.phone,
         u.role,
         e.employee_id,
         e.employee_code,
         e.job_title,
         e.employment_status,
         e.hire_date,
         e.pay_rate_hourly
     FROM users u
     LEFT JOIN employees e ON e.user_id = u.user_id
     WHERE u.role = 'Staff' AND e.employee_id IS NOT NULL
    """

    params = []
    if status == 'active':
        base_sql += " AND u.is_active = TRUE"
    elif status == 'inactive':
        base_sql += " AND u.is_active = FALSE"

    if search:
        # match against name or email
        base_sql += " AND (CONCAT(u.first_name, ' ', u.last_name) LIKE %s OR u.email LIKE %s)"
        like_term = f"%{search}%"
        params.extend([like_term, like_term])

    base_sql += " ORDER BY u.user_id"

    cur.execute(base_sql, tuple(params))
    employees = cur.fetchall()
    cur.close()

    employee_list = []
    for emp in employees:
        employee_list.append({
            'id': emp[0],
            'name': emp[1],
            'email': emp[2],
            'is_active': bool(emp[3]),
            'phone': emp[4],
            'role': emp[5],
            'employee_id': emp[6],
            'employee_code': emp[7],
            'job_title': emp[8],
            'employment_status': emp[9],
            'hire_date': emp[10].isoformat() if emp[10] is not None else None,
            'pay_rate_hourly': float(emp[11]) if emp[11] is not None else None
        })

    return jsonify(employee_list)


@app.route('/api/management/employee-stats', methods=['GET'])
@login_required
@role_required('Management')
def get_employee_stats():
    cur = mysql.connection.cursor()
    today = datetime.now().date()

    # Total active employees
    cur.execute("""
        SELECT COUNT(*) FROM users u
        JOIN employees e ON e.user_id = u.user_id
        WHERE u.role = 'Staff' AND u.is_active = TRUE
    """)
    total = cur.fetchone()[0]

    # On active job today
    cur.execute("""
        SELECT COUNT(DISTINCT e.employee_id)
        FROM employees e
        JOIN users u ON u.user_id = e.user_id
        JOIN job_orders jo ON jo.assigned_employee_id = e.employee_id
        WHERE u.is_active = TRUE AND jo.scheduled_date = %s
    """, (today,))
    on_job = cur.fetchone()[0]

    cur.close()
    available = max(0, total - on_job)
    return jsonify({'total': total, 'available': available, 'on_job': on_job})


# --- Services API ---
@app.route('/services', methods=['GET'])
@login_required
def get_services():
    search = request.args.get('search', '').strip()
    include_inactive = request.args.get('include_inactive', '').strip().lower() == 'true'

    show_all = current_user.role == 'Management' and include_inactive

    base_sql = """
        SELECT service_id, service_name, description, base_price, COALESCE(is_active, TRUE) AS is_active
        FROM services
    """
    params = []

    where_clauses = []
    if not show_all:
        where_clauses.append("COALESCE(is_active, TRUE) = TRUE")

    if search:
        where_clauses.append("(service_name LIKE %s OR description LIKE %s)")
        like_term = f"%{search}%"
        params.extend([like_term, like_term])

    if where_clauses:
        base_sql += " WHERE " + " AND ".join(where_clauses)

    base_sql += " ORDER BY service_name"

    cur = mysql.connection.cursor()
    cur.execute(base_sql, tuple(params))
    rows = cur.fetchall()
    cur.close()

    services = []
    for row in rows:
        services.append({
            'service_id': row[0],
            'service_name': row[1],
            'description': row[2],
            'base_price': float(row[3]) if row[3] is not None else 0.0,
            'is_active': bool(row[4])
        })

    return jsonify(services)


@app.route('/services', methods=['POST'])
@login_required
@role_required('Management')
def add_service():
    if not request.is_json:
        return jsonify(error='Request must be JSON'), 400

    data = request.get_json()
    service_name = (data.get('service_name') or '').strip()
    description = data.get('description', '').strip()
    base_price = data.get('base_price')

    if not service_name or base_price in (None, ''):
        return jsonify(error='service_name and base_price are required'), 400

    try:
        base_price = float(base_price)
    except ValueError:
        return jsonify(error='base_price must be a number'), 400

    cur = mysql.connection.cursor()
    cur.execute("SELECT service_id FROM services WHERE service_name = %s LIMIT 1", (service_name,))
    if cur.fetchone():
        cur.close()
        return jsonify(error='A service with that name already exists'), 400

    cur.execute(
        "INSERT INTO services (service_name, description, base_price, is_active) VALUES (%s, %s, %s, TRUE)",
        (service_name, description, base_price)
    )
    mysql.connection.commit()
    service_id = cur.lastrowid
    cur.close()

    return jsonify(message='Service added successfully', service_id=service_id), 201


@app.route('/services/<int:service_id>', methods=['PUT'])
@login_required
@role_required('Management')
def update_service(service_id):
    if not request.is_json:
        return jsonify(error='Request must be JSON'), 400

    data = request.get_json()
    service_name = (data.get('service_name') or '').strip()
    description = (data.get('description') or '').strip()
    base_price = data.get('base_price')

    if not service_name or base_price in (None, ''):
        return jsonify(error='service_name and base_price are required'), 400

    try:
        base_price = float(base_price)
    except ValueError:
        return jsonify(error='base_price must be a number'), 400

    cur = mysql.connection.cursor()
    cur.execute(
        """
        SELECT service_id
        FROM services
        WHERE service_name = %s AND service_id <> %s
        LIMIT 1
        """,
        (service_name, service_id)
    )
    if cur.fetchone():
        cur.close()
        return jsonify(error='Another service already uses that name'), 400

    cur.execute(
        """
        UPDATE services
        SET service_name = %s,
            description = %s,
            base_price = %s
        WHERE service_id = %s
        """,
        (service_name, description, base_price, service_id)
    )
    if cur.rowcount == 0:
        cur.close()
        return jsonify(error='Service not found'), 404

    mysql.connection.commit()
    cur.close()
    return jsonify(message='Service updated successfully')


@app.route('/services/<int:service_id>/deactivate', methods=['POST'])
@login_required
@role_required('Management')
def deactivate_service(service_id):
    cur = mysql.connection.cursor()
    cur.execute(
        "UPDATE services SET is_active = FALSE WHERE service_id = %s",
        (service_id,)
    )
    if cur.rowcount == 0:
        cur.close()
        return jsonify(error='Service not found'), 404

    mysql.connection.commit()
    cur.close()
    return jsonify(message='Service deactivated successfully')


@app.route('/services/<int:service_id>/reactivate', methods=['POST'])
@login_required
@role_required('Management')
def reactivate_service(service_id):
    cur = mysql.connection.cursor()
    cur.execute(
        "UPDATE services SET is_active = TRUE WHERE service_id = %s",
        (service_id,)
    )
    if cur.rowcount == 0:
        cur.close()
        return jsonify(error='Service not found'), 404

    mysql.connection.commit()
    cur.close()
    return jsonify(message='Service reactivated successfully')


# --- Suppliers API ---
@app.route('/suppliers', methods=['GET'])
@login_required
@role_required('Management')
def get_suppliers():
    cur = mysql.connection.cursor()
    search = request.args.get('search', '').strip()

    base_sql = """
        SELECT supplier_id, supplier_name, phone, email, total_orders, last_order_date, status, is_active
        FROM suppliers
    """

    params = []
    if search:
        base_sql += " WHERE supplier_name LIKE %s OR email LIKE %s"
        like_term = f"%{search}%"
        params.extend([like_term, like_term])

    base_sql += " ORDER BY supplier_name"

    cur.execute(base_sql, tuple(params))
    suppliers = cur.fetchall()
    cur.close()

    supplier_list = []
    for sup in suppliers:
        supplier_list.append({
            'supplier_id': sup[0],
            'supplier_name': sup[1],
            'phone': sup[2],
            'email': sup[3],
            'total_orders': sup[4],
            'last_order_date': sup[5].isoformat() if sup[5] is not None else None,
            'status': sup[6] or ('Active' if sup[7] else 'Inactive'),
            'is_active': bool(sup[7])
        })

    return jsonify(supplier_list)


@app.route('/suppliers/<int:supplier_id>/deactivate', methods=['POST'])
@login_required
@role_required('Management')
def deactivate_supplier(supplier_id):
    cur = mysql.connection.cursor()
    cur.execute("""
        UPDATE suppliers
        SET is_active = FALSE, status = 'Inactive'
        WHERE supplier_id = %s
    """, (supplier_id,))
    mysql.connection.commit()
    cur.close()
    return jsonify(message='Supplier deactivated successfully')


@app.route('/suppliers/<int:supplier_id>/reactivate', methods=['POST'])
@login_required
@role_required('Management')
def reactivate_supplier(supplier_id):
    cur = mysql.connection.cursor()
    cur.execute("""
        UPDATE suppliers
        SET is_active = TRUE, status = 'Active'
        WHERE supplier_id = %s
    """, (supplier_id,))
    mysql.connection.commit()
    cur.close()
    return jsonify(message='Supplier reactivated successfully')


@app.route('/suppliers', methods=['POST'])
@login_required
@role_required('Management')
def add_supplier():
    if not request.is_json:
        return jsonify(error='Request must be JSON'), 400

    data = request.get_json()
    supplier_name = (data.get('supplier_name') or '').strip()
    phone = data.get('phone', '').strip()
    email = data.get('email', '').strip()

    if not supplier_name or not email:
        return jsonify(error='supplier_name and email are required'), 400

    cur = mysql.connection.cursor()
    cur.execute(
        "INSERT INTO suppliers (supplier_name, phone, email) VALUES (%s, %s, %s)",
        (supplier_name, phone, email)
    )
    mysql.connection.commit()
    supplier_id = cur.lastrowid
    cur.close()

    return jsonify(message='Supplier added successfully', supplier_id=supplier_id), 201


# --- Jobs API (Management) ---
@app.route('/jobs', methods=['GET'])
@login_required
@role_required('Management')
def get_jobs():
    cur = mysql.connection.cursor()

    cur.execute(
        """
        SELECT jo.job_order_id,
               jo.job_order_code,
               jo.title,
               c.company_name,
               jo.scheduled_date,
               jo.start_time,
               jo.end_time,
               addr.street_1,
               addr.city,
               addr.state,
               jo.location_id,
               jo.assigned_employee_id,
               u.first_name,
               u.last_name,
               jo.status,
               jo.service_request_id,
               jo.priority,
               jo.created_at
        FROM job_orders jo
        LEFT JOIN clients c ON jo.client_id = c.client_id
        LEFT JOIN client_locations cl ON jo.location_id = cl.location_id
        LEFT JOIN addresses addr ON cl.address_id = addr.address_id
        LEFT JOIN employees e ON jo.assigned_employee_id = e.employee_id
        LEFT JOIN users u ON e.user_id = u.user_id
        ORDER BY jo.scheduled_date IS NULL, jo.scheduled_date, jo.start_time
        """
    )
    rows = cur.fetchall()
    cur.close()

    jobs = []
    for r in rows:
        job_id = r[0]
        job_order_code = r[1]
        title = r[2]
        company = r[3]
        scheduled_date = r[4].isoformat() if r[4] is not None else None
        start_time = format_time_hhmm(r[5]) if r[5] is not None else None
        end_time = format_time_hhmm(r[6]) if r[6] is not None else None
        street = r[7]
        city = r[8]
        state = r[9]
        location = None
        if street:
            location = street
            if city:
                location += ', ' + city
            if state:
                location += ', ' + state
        assigned_employee_id = r[11]
        assigned_name = None
        if r[12] and r[13]:
            assigned_name = f"{r[12]} {r[13]}"
        status = r[14]
        service_request_id = r[15]
        priority = r[16] or 'Normal'
        approved_at = r[17].isoformat() if r[17] is not None else None

        jobs.append({
            'id': job_id,
            'job_order_code': job_order_code,
            'title': title,
            'company': company,
            'scheduled_date': scheduled_date,
            'start_time': start_time,
            'end_time': end_time,
            'location': location,
            'assigned_employee_id': assigned_employee_id,
            'assigned_name': assigned_name,
            'status': status,
            'service_request_id': service_request_id,
            'priority': priority,
            'approved_at': approved_at
        })

    return jsonify(jobs)


@app.route('/api/management/available-employees', methods=['GET'])
@login_required
@role_required('Management')
def get_available_employees_api():
    scheduled_date_raw = (request.args.get('scheduled_date') or '').strip()
    start_time_raw = (request.args.get('start_time') or '').strip()
    end_time_raw = (request.args.get('end_time') or '').strip()
    exclude_job_id_raw = (request.args.get('exclude_job_id') or '').strip()

    scheduled_date = parse_iso_date(scheduled_date_raw)
    start_time = parse_time_value(start_time_raw)
    end_time = parse_time_value(end_time_raw)

    if not scheduled_date:
        return jsonify(error='scheduled_date is required (YYYY-MM-DD)'), 400
    if not start_time or not end_time:
        return jsonify(error='start_time and end_time are required (HH:MM)'), 400
    if end_time <= start_time:
        return jsonify(error='end_time must be later than start_time'), 400

    exclude_job_id = None
    if exclude_job_id_raw:
        try:
            exclude_job_id = int(exclude_job_id_raw)
        except Exception:
            return jsonify(error='exclude_job_id must be an integer when provided'), 400

    try:
        cur = mysql.connection.cursor()
        available, unavailable = list_available_employees_for_window(
            cur,
            scheduled_date,
            start_time,
            end_time,
            exclude_job_id=exclude_job_id
        )
        cur.close()

        return jsonify({
            'scheduled_date': scheduled_date.isoformat(),
            'start_time': format_time_hhmm(start_time),
            'end_time': format_time_hhmm(end_time),
            'available': available,
            'unavailable': unavailable
        })
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load available employees: {str(e)}'), 500


@app.route('/api/management/available-employees/suggestions', methods=['GET'])
@login_required
@role_required('Management')
def get_available_employee_suggestions_api():
    scheduled_date_raw = (request.args.get('scheduled_date') or '').strip()
    scheduled_date = parse_iso_date(scheduled_date_raw)
    if not scheduled_date:
        return jsonify(error='scheduled_date is required (YYYY-MM-DD)'), 400

    try:
        cur = mysql.connection.cursor()

        suggestions = []
        for hour in range(8, 22):
            start_value = f"{hour:02d}:00"
            end_value = f"{hour + 1:02d}:00"
            available, unavailable = list_available_employees_for_window(
                cur,
                scheduled_date,
                start_value,
                end_value
            )
            if available:
                suggestions.append({
                    'start_time': start_value,
                    'end_time': end_value,
                    'available_count': len(available),
                    'available': available
                })
                if len(suggestions) >= 5:
                    break

        no_availability_reasons = []
        if not suggestions:
            _, unavailable = list_available_employees_for_window(
                cur,
                scheduled_date,
                '12:00',
                '13:00'
            )
            no_availability_reasons = unavailable

        cur.close()

        return jsonify({
            'scheduled_date': scheduled_date.isoformat(),
            'suggestions': suggestions,
            'no_availability_reasons': no_availability_reasons
        })
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load employee suggestions: {str(e)}'), 500


@app.route('/api/management/employees/<int:employee_id>/assignable-jobs', methods=['GET'])
@login_required
@role_required('Management')
def get_assignable_jobs_for_employee_api(employee_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute(
            """
            SELECT e.employee_id
            FROM employees e
            JOIN users u ON u.user_id = e.user_id
            WHERE e.employee_id = %s
              AND u.role = 'Staff'
              AND u.is_active = TRUE
            LIMIT 1
            """,
            (employee_id,)
        )
        if not cur.fetchone():
            cur.close()
            return jsonify(error='Employee not found or inactive'), 404

        cur.execute(
            """
            SELECT jo.job_order_id,
                   jo.job_order_code,
                   jo.title,
                   c.company_name,
                   jo.scheduled_date,
                   jo.start_time,
                   jo.end_time,
                   jo.assigned_employee_id,
                   assign_u.first_name,
                   assign_u.last_name,
                   jo.status
            FROM job_orders jo
            LEFT JOIN clients c ON c.client_id = jo.client_id
            LEFT JOIN employees assign_e ON assign_e.employee_id = jo.assigned_employee_id
            LEFT JOIN users assign_u ON assign_u.user_id = assign_e.user_id
            WHERE jo.scheduled_date IS NOT NULL
              AND jo.start_time IS NOT NULL
              AND jo.end_time IS NOT NULL
              AND LOWER(COALESCE(jo.status, '')) NOT IN ('completed', 'cancelled', 'canceled')
            ORDER BY jo.scheduled_date, jo.start_time
            """
        )
        rows = cur.fetchall()

        jobs = []
        for row in rows:
            job_id = row[0]
            assigned_name = None
            if row[8] and row[9]:
                assigned_name = f"{row[8]} {row[9]}"
            eligibility = check_employee_assignment_eligibility(
                cur,
                employee_id,
                row[4],
                row[5],
                row[6],
                exclude_job_id=job_id
            )
            jobs.append({
                'job_id': job_id,
                'job_order_code': row[1],
                'title': row[2] or '',
                'company': row[3] or '',
                'scheduled_date': row[4].isoformat() if row[4] else None,
                'start_time': format_time_hhmm(row[5]),
                'end_time': format_time_hhmm(row[6]),
                'assigned_employee_id': row[7],
                'assigned_name': assigned_name,
                'status': row[10] or '',
                'can_assign': bool(eligibility.get('is_available')),
                'reason': eligibility.get('reason')
            })

        cur.close()
        return jsonify(jobs)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load assignable jobs: {str(e)}'), 500


@app.route('/jobs/<int:job_id>/assign', methods=['POST'])
@login_required
@role_required('Management')
def assign_job(job_id):
    data = None
    try:
        if request.is_json:
            data = request.get_json()
        else:
            data = request.form.to_dict()
    except Exception:
        return jsonify(error='Invalid request body'), 400

    employee_id = data.get('employee_id')
    # allow null/unassign
    if employee_id in ('', None):
        assigned_val = None
    else:
        try:
            assigned_val = int(employee_id)
        except Exception:
            return jsonify(error='employee_id must be integer or null'), 400

    cur = mysql.connection.cursor()
    try:
        cur.execute(
            """
            SELECT job_order_id,
                   scheduled_date,
                   start_time,
                   end_time
            FROM job_orders
            WHERE job_order_id = %s
            LIMIT 1
            """,
            (job_id,)
        )
        job_row = cur.fetchone()
        if not job_row:
            cur.close()
            return jsonify(error='Job not found'), 404

        if assigned_val is None:
            cur.execute(
                "UPDATE job_orders SET assigned_employee_id = NULL, status = %s WHERE job_order_id = %s",
                ('Unassigned', job_id)
            )
            mysql.connection.commit()
            cur.close()
            return jsonify(message='Assignment removed')

        scheduled_date = parse_iso_date(job_row[1])
        start_time = parse_time_value(job_row[2])
        end_time = parse_time_value(job_row[3])
        if not scheduled_date or not start_time or not end_time:
            cur.close()
            return jsonify(error='Job must have scheduled_date, start_time, and end_time before assignment'), 400

        eligibility = check_employee_assignment_eligibility(
            cur,
            assigned_val,
            scheduled_date,
            start_time,
            end_time,
            exclude_job_id=job_id
        )
        if not eligibility.get('is_available'):
            cur.close()
            return jsonify(error=eligibility.get('reason') or 'Employee is not available for this time window'), 400

        cur.execute(
            """
            UPDATE job_orders
            SET assigned_employee_id = %s,
                status = %s
            WHERE job_order_id = %s
            """,
            (assigned_val, 'Scheduled', job_id)
        )
        mysql.connection.commit()
        cur.close()
        return jsonify(
            message='Assignment updated',
            employee_id=assigned_val,
            employee_name=eligibility.get('employee_name')
        )
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        mysql.connection.rollback()
        return jsonify(error=f'Failed to update assignment: {str(e)}'), 500

# ========================
# CLIENT PROFILE + LOCATION API
# ========================

@app.route('/api/client/profile', methods=['GET'])
@login_required
@role_required('Client')
def get_client_profile_api():
    try:
        cur = mysql.connection.cursor()
        created_client_id = ensure_client_record(cur, current_user.id)

        cur.execute(
            """
            SELECT u.user_id,
                   u.first_name,
                   u.last_name,
                   u.email,
                   u.phone,
                   c.client_id,
                   c.company_name,
                   c.member_since,
                   c.account_status
            FROM users u
            LEFT JOIN clients c ON c.contact_user_id = u.user_id
            WHERE u.user_id = %s
            LIMIT 1
            """,
            (current_user.id,)
        )
        row = cur.fetchone()
        mysql.connection.commit()
        cur.close()

        if not row:
            return jsonify(error='Client profile not found'), 404

        return jsonify({
            'user_id': row[0],
            'first_name': row[1] or '',
            'last_name': row[2] or '',
            'email': row[3] or '',
            'phone': row[4] or '',
            'client_id': row[5] or created_client_id,
            'company_name': row[6] or '',
            'member_since': row[7].isoformat() if row[7] else None,
            'account_status': row[8] or 'Active'
        })
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load profile: {str(e)}'), 500


@app.route('/api/client/profile', methods=['PUT'])
@login_required
@role_required('Client')
def update_client_profile_api():
    if not request.is_json:
        return jsonify(error='Request must be JSON'), 400

    data = request.get_json()
    first_name = (data.get('first_name') or '').strip()
    last_name = (data.get('last_name') or '').strip()
    phone = (data.get('phone') or '').strip()
    company_name = (data.get('company_name') or '').strip()

    if not first_name or not last_name:
        return jsonify(error='first_name and last_name are required'), 400
    if not company_name:
        return jsonify(error='company_name is required'), 400

    try:
        cur = mysql.connection.cursor()
        client_id = ensure_client_record(cur, current_user.id, company_name)

        cur.execute(
            """
            UPDATE users
            SET first_name = %s,
                last_name = %s,
                phone = %s
            WHERE user_id = %s
            """,
            (first_name, last_name, phone, current_user.id)
        )

        cur.execute(
            """
            UPDATE clients
            SET company_name = %s
            WHERE client_id = %s
            """,
            (company_name, client_id)
        )

        mysql.connection.commit()
        cur.close()
        return jsonify(message='Profile updated successfully')
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to update profile: {str(e)}'), 500


@app.route('/api/client/locations', methods=['GET'])
@login_required
@role_required('Client')
def get_client_locations_api():
    try:
        cur = mysql.connection.cursor()
        client_id = ensure_client_record(cur, current_user.id)

        cur.execute(
            """
            SELECT cl.location_id,
                   cl.location_name,
                   a.street_1,
                   a.city,
                   a.state,
                   a.zip_code,
                   COALESCE(cl.is_active, TRUE) AS is_active
            FROM client_locations cl
            JOIN addresses a ON a.address_id = cl.address_id
            WHERE cl.client_id = %s
              AND COALESCE(cl.is_active, TRUE) = TRUE
            ORDER BY cl.location_id DESC
            """,
            (client_id,)
        )
        rows = cur.fetchall()
        mysql.connection.commit()
        cur.close()

        locations = []
        for row in rows:
            locations.append({
                'location_id': row[0],
                'location_name': row[1] or '',
                'street_1': row[2] or '',
                'city': row[3] or '',
                'state': row[4] or '',
                'zip_code': row[5] or '',
                'is_active': bool(row[6])
            })

        return jsonify(locations)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load locations: {str(e)}'), 500


@app.route('/api/client/locations', methods=['POST'])
@login_required
@role_required('Client')
def add_client_location_api():
    if not request.is_json:
        return jsonify(error='Request must be JSON'), 400

    data = request.get_json()
    location_name = (data.get('location_name') or '').strip()
    street_1 = (data.get('street_1') or '').strip()
    city = (data.get('city') or '').strip()
    state = (data.get('state') or '').strip()
    zip_code = (data.get('zip_code') or '').strip()

    if not location_name or not street_1 or not city or not state or not zip_code:
        return jsonify(error='location_name, street_1, city, state, zip_code are required'), 400

    try:
        cur = mysql.connection.cursor()
        client_id = ensure_client_record(cur, current_user.id)

        cur.execute(
            """
            INSERT INTO addresses (street_1, city, state, zip_code)
            VALUES (%s, %s, %s, %s)
            """,
            (street_1, city, state, zip_code)
        )
        address_id = cur.lastrowid

        cur.execute(
            """
            INSERT INTO client_locations (client_id, address_id, location_name, is_active)
            VALUES (%s, %s, %s, TRUE)
            """,
            (client_id, address_id, location_name)
        )
        location_id = cur.lastrowid

        mysql.connection.commit()
        cur.close()
        return jsonify(message='Location added successfully', location_id=location_id), 201
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to add location: {str(e)}'), 500


@app.route('/api/client/locations/<int:location_id>', methods=['PUT'])
@login_required
@role_required('Client')
def update_client_location_api(location_id):
    if not request.is_json:
        return jsonify(error='Request must be JSON'), 400

    data = request.get_json()
    location_name = (data.get('location_name') or '').strip()
    street_1 = (data.get('street_1') or '').strip()
    city = (data.get('city') or '').strip()
    state = (data.get('state') or '').strip()
    zip_code = (data.get('zip_code') or '').strip()

    if not location_name or not street_1 or not city or not state or not zip_code:
        return jsonify(error='location_name, street_1, city, state, zip_code are required'), 400

    try:
        cur = mysql.connection.cursor()
        client_id = ensure_client_record(cur, current_user.id)

        cur.execute(
            """
            SELECT address_id
            FROM client_locations
            WHERE location_id = %s
              AND client_id = %s
              AND COALESCE(is_active, TRUE) = TRUE
            LIMIT 1
            """,
            (location_id, client_id)
        )
        found = cur.fetchone()
        if not found:
            cur.close()
            return jsonify(error='Location not found'), 404

        address_id = found[0]

        cur.execute(
            """
            UPDATE addresses
            SET street_1 = %s,
                city = %s,
                state = %s,
                zip_code = %s
            WHERE address_id = %s
            """,
            (street_1, city, state, zip_code, address_id)
        )

        cur.execute(
            """
            UPDATE client_locations
            SET location_name = %s
            WHERE location_id = %s
            """,
            (location_name, location_id)
        )

        mysql.connection.commit()
        cur.close()
        return jsonify(message='Location updated successfully')
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to update location: {str(e)}'), 500


@app.route('/api/client/locations/<int:location_id>', methods=['DELETE'])
@login_required
@role_required('Client')
def delete_client_location_api(location_id):
    try:
        cur = mysql.connection.cursor()
        client_id = ensure_client_record(cur, current_user.id)

        cur.execute(
            """
            UPDATE client_locations
            SET is_active = FALSE
            WHERE location_id = %s
              AND client_id = %s
            """,
            (location_id, client_id)
        )
        if cur.rowcount == 0:
            cur.close()
            return jsonify(error='Location not found'), 404

        mysql.connection.commit()
        cur.close()
        return jsonify(message='Location removed successfully')
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to remove location: {str(e)}'), 500


@app.route('/api/client/service-requests', methods=['POST'])
@login_required
@role_required('Client')
def create_client_service_request_api():
    if not request.is_json:
        return jsonify(error='Request must be JSON'), 400

    data = request.get_json()
    service_id_raw = data.get('service_id')
    location_id_raw = data.get('location_id')
    requested_date_raw = (data.get('requested_date') or '').strip()
    requested_notes = (data.get('requested_notes') or '').strip()

    if service_id_raw in (None, ''):
        return jsonify(error='service_id is required'), 400
    if location_id_raw in (None, ''):
        return jsonify(error='location_id is required'), 400
    if not requested_date_raw:
        return jsonify(error='requested_date is required (YYYY-MM-DD)'), 400

    try:
        service_id = int(service_id_raw)
        location_id = int(location_id_raw)
    except Exception:
        return jsonify(error='service_id and location_id must be integers'), 400

    try:
        requested_date = datetime.strptime(requested_date_raw, '%Y-%m-%d').date()
    except ValueError:
        return jsonify(error='requested_date must be YYYY-MM-DD'), 400

    try:
        cur = mysql.connection.cursor()
        client_id = ensure_client_record(cur, current_user.id)

        cur.execute(
            """
            SELECT cl.location_id,
                   cl.location_name,
                   a.street_1,
                   a.city,
                   a.state,
                   a.zip_code
            FROM client_locations cl
            JOIN addresses a ON a.address_id = cl.address_id
            WHERE cl.location_id = %s
              AND cl.client_id = %s
              AND COALESCE(cl.is_active, TRUE) = TRUE
            LIMIT 1
            """,
            (location_id, client_id)
        )
        location_row = cur.fetchone()
        if not location_row:
            cur.close()
            return jsonify(error='Selected location was not found for your account'), 404

        cur.execute(
            """
            SELECT service_id, service_name, base_price
            FROM services
            WHERE service_id = %s
              AND COALESCE(is_active, TRUE) = TRUE
            LIMIT 1
            """,
            (service_id,)
        )
        service_row = cur.fetchone()
        if not service_row:
            cur.close()
            return jsonify(error='Selected service is not available'), 404

        cur.execute(
            """
            INSERT INTO service_requests (client_id, location_id, service_id, requested_date, requested_notes, status)
            VALUES (%s, %s, %s, %s, %s, %s)
            """,
            (client_id, location_id, service_id, requested_date, requested_notes, 'Pending')
        )
        service_request_id = cur.lastrowid

        mysql.connection.commit()
        cur.close()

        full_location = location_row[2] or ''
        if location_row[3]:
            full_location += ', ' + location_row[3]
        if location_row[4]:
            full_location += ', ' + location_row[4]
        if location_row[5]:
            full_location += ' ' + location_row[5]

        return jsonify(
            message='Service request submitted successfully',
            service_request_id=service_request_id,
            status='Pending',
            client_id=client_id,
            service_id=service_id,
            service_name=service_row[1],
            base_price=float(service_row[2]) if service_row[2] is not None else 0.0,
            location_id=location_id,
            location_name=location_row[1] or '',
            location_address=full_location.strip(),
            requested_date=requested_date.isoformat(),
            requested_notes=requested_notes
        ), 201
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        mysql.connection.rollback()
        return jsonify(error=f'Failed to submit service request: {str(e)}'), 500


@app.route('/api/client/service-requests', methods=['GET'])
@login_required
@role_required('Client')
def get_client_service_requests_api():
    status = request.args.get('status', 'all').strip().lower()
    if status not in ('pending', 'approved', 'rejected', 'all'):
        return jsonify(error='status must be one of pending, approved, rejected, all'), 400

    try:
        cur = mysql.connection.cursor()
        client_id = ensure_client_record(cur, current_user.id)

        base_sql = """
            SELECT sr.service_request_id,
                   sr.requested_date,
                   sr.requested_notes,
                   COALESCE(sr.status, 'Pending') AS status,
                   sr.created_at,
                   sr.service_id,
                   s.service_name,
                   s.base_price,
                   sr.location_id,
                   cl.location_name,
                   a.street_1,
                   a.city,
                   a.state,
                   a.zip_code
            FROM service_requests sr
            JOIN services s ON s.service_id = sr.service_id
            JOIN client_locations cl ON cl.location_id = sr.location_id
            JOIN addresses a ON a.address_id = cl.address_id
            WHERE sr.client_id = %s
        """
        params = [client_id]

        if status != 'all':
            base_sql += " AND LOWER(COALESCE(sr.status, 'Pending')) = %s"
            params.append(status)

        base_sql += " ORDER BY sr.created_at DESC, sr.service_request_id DESC"

        cur.execute(base_sql, tuple(params))
        rows = cur.fetchall()
        cur.close()

        requests_out = []
        for row in rows:
            location_address = row[10] or ''
            if row[11]:
                location_address += ', ' + row[11]
            if row[12]:
                location_address += ', ' + row[12]
            if row[13]:
                location_address += ' ' + row[13]

            requests_out.append({
                'service_request_id': row[0],
                'requested_date': row[1].isoformat() if row[1] else None,
                'requested_notes': row[2] or '',
                'status': row[3] or 'Pending',
                'created_at': row[4].isoformat() if row[4] else None,
                'service_id': row[5],
                'service_name': row[6] or '',
                'base_price': float(row[7]) if row[7] is not None else 0.0,
                'location_id': row[8],
                'location_name': row[9] or '',
                'location_address': location_address.strip()
            })

        return jsonify(requests_out)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load service requests: {str(e)}'), 500


@app.route('/api/management/service-requests', methods=['GET'])
@login_required
@role_required('Management')
def get_management_service_requests_api():
    status = request.args.get('status', 'pending').strip().lower()
    search = request.args.get('search', '').strip()

    if status not in ('pending', 'approved', 'rejected', 'all'):
        return jsonify(error='status must be one of pending, approved, rejected, all'), 400

    base_sql = """
        SELECT sr.service_request_id,
               sr.client_id,
               c.company_name,
               u.first_name,
               u.last_name,
               u.email,
               u.phone,
               sr.location_id,
               cl.location_name,
               a.street_1,
               a.city,
               a.state,
               a.zip_code,
               sr.service_id,
               s.service_name,
               s.base_price,
               sr.requested_date,
               sr.requested_notes,
               COALESCE(sr.status, 'Pending') AS status,
               sr.created_at,
               approver.first_name,
               approver.last_name
        FROM service_requests sr
        JOIN clients c ON c.client_id = sr.client_id
        LEFT JOIN users u ON u.user_id = c.contact_user_id
        JOIN client_locations cl ON cl.location_id = sr.location_id
        JOIN addresses a ON a.address_id = cl.address_id
        JOIN services s ON s.service_id = sr.service_id
        LEFT JOIN users approver ON approver.user_id = sr.approved_by
    """

    where_clauses = []
    params = []

    if status != 'all':
        where_clauses.append("LOWER(COALESCE(sr.status, 'Pending')) = %s")
        params.append(status)

    if search:
        where_clauses.append(
            """
            (
                c.company_name LIKE %s
                OR s.service_name LIKE %s
                OR cl.location_name LIKE %s
                OR CONCAT(COALESCE(u.first_name, ''), ' ', COALESCE(u.last_name, '')) LIKE %s
            )
            """
        )
        like_term = f"%{search}%"
        params.extend([like_term, like_term, like_term, like_term])

    if where_clauses:
        base_sql += " WHERE " + " AND ".join(where_clauses)

    base_sql += """
        ORDER BY
            (LOWER(COALESCE(sr.status, 'Pending')) <> 'pending'),
            sr.created_at DESC,
            sr.service_request_id DESC
    """

    try:
        cur = mysql.connection.cursor()
        cur.execute(base_sql, tuple(params))
        rows = cur.fetchall()
        cur.close()

        requests_out = []
        for row in rows:
            contact_name = ((row[3] or '') + ' ' + (row[4] or '')).strip()
            approved_by_name = ((row[20] or '') + ' ' + (row[21] or '')).strip()

            location_address = row[9] or ''
            if row[10]:
                location_address += ', ' + row[10]
            if row[11]:
                location_address += ', ' + row[11]
            if row[12]:
                location_address += ' ' + row[12]

            requests_out.append({
                'service_request_id': row[0],
                'client_id': row[1],
                'company_name': row[2] or '',
                'contact_name': contact_name,
                'contact_email': row[5] or '',
                'contact_phone': row[6] or '',
                'location_id': row[7],
                'location_name': row[8] or '',
                'location_address': location_address.strip(),
                'service_id': row[13],
                'service_name': row[14] or '',
                'base_price': float(row[15]) if row[15] is not None else 0.0,
                'requested_date': row[16].isoformat() if row[16] else None,
                'requested_notes': row[17] or '',
                'status': row[18] or 'Pending',
                'created_at': row[19].isoformat() if row[19] else None,
                'approved_by_name': approved_by_name
            })

        return jsonify(requests_out)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load management service requests: {str(e)}'), 500


@app.route('/api/management/service-requests/<int:service_request_id>/approve', methods=['POST'])
@login_required
@role_required('Management')
def approve_management_service_request_api(service_request_id):
    payload = request.get_json(silent=True) or {}
    employee_id_raw = payload.get('employee_id')
    requested_schedule = (payload.get('scheduled_date') or '').strip()
    requested_start = (payload.get('start_time') or '').strip()
    requested_end = (payload.get('end_time') or '').strip()
    priority = (payload.get('priority') or 'Normal').strip() or 'Normal'
    override_description = (payload.get('job_description') or '').strip()

    if employee_id_raw in (None, ''):
        return jsonify(error='employee_id is required'), 400
    try:
        employee_id = int(employee_id_raw)
    except Exception:
        return jsonify(error='employee_id must be an integer'), 400

    parsed_start = parse_time_value(requested_start)
    parsed_end = parse_time_value(requested_end)
    if not parsed_start or not parsed_end:
        return jsonify(error='start_time and end_time are required and must be HH:MM'), 400
    if parsed_end <= parsed_start:
        return jsonify(error='end_time must be later than start_time'), 400

    try:
        cur = mysql.connection.cursor()
        cur.execute(
            """
            SELECT sr.service_request_id,
                   sr.client_id,
                   sr.location_id,
                   sr.service_id,
                   sr.requested_date,
                   sr.requested_notes,
                   COALESCE(sr.status, 'Pending') AS status,
                   s.service_name,
                   s.description,
                   s.base_price,
                   c.company_name
            FROM service_requests sr
            JOIN services s ON s.service_id = sr.service_id
            JOIN clients c ON c.client_id = sr.client_id
            WHERE sr.service_request_id = %s
            LIMIT 1
            """,
            (service_request_id,)
        )
        row = cur.fetchone()
        if not row:
            cur.close()
            return jsonify(error='Service request not found'), 404

        current_status = (row[6] or 'Pending').strip().lower()
        if current_status != 'pending':
            cur.close()
            return jsonify(error=f'Service request is already {row[6]}'), 400

        scheduled_date = parse_iso_date(row[4])
        if not scheduled_date:
            cur.close()
            return jsonify(error='Request cannot be approved because requested date is missing'), 400

        if requested_schedule and requested_schedule != scheduled_date.isoformat():
            cur.close()
            return jsonify(error='Management cannot change the requested service date during approval'), 400

        eligibility = check_employee_assignment_eligibility(
            cur,
            employee_id,
            scheduled_date,
            parsed_start,
            parsed_end
        )
        if not eligibility.get('is_available'):
            cur.close()
            return jsonify(error=eligibility.get('reason') or 'Selected employee is not available'), 400

        description = (
            override_description
            or row[5]
            or row[8]
            or f"Service request submitted by {row[10] or 'client'}"
        )
        estimated_cost = float(row[9]) if row[9] is not None else 0.0
        title = row[7] or 'Service Request'
        job_order_code = generate_job_order_code(cur)

        cur.execute(
            """
            INSERT INTO job_orders (
                job_order_code,
                client_id,
                location_id,
                service_id,
                service_request_id,
                assigned_employee_id,
                title,
                description,
                scheduled_date,
                start_time,
                end_time,
                estimated_cost,
                status,
                priority
            )
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s)
            """,
            (
                job_order_code,
                row[1],
                row[2],
                row[3],
                row[0],
                employee_id,
                title,
                description,
                scheduled_date,
                parsed_start,
                parsed_end,
                estimated_cost,
                'Scheduled',
                priority
            )
        )
        job_order_id = cur.lastrowid

        cur.execute(
            """
            UPDATE service_requests
            SET status = %s,
                approved_by = %s
            WHERE service_request_id = %s
            """,
            ('Approved', current_user.id, service_request_id)
        )

        mysql.connection.commit()
        cur.close()

        return jsonify(
            message='Service request approved and job order created',
            service_request_id=service_request_id,
            job_order_id=job_order_id,
            job_order_code=job_order_code,
            status='Approved',
            employee_id=employee_id,
            employee_name=eligibility.get('employee_name')
        )
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        mysql.connection.rollback()
        return jsonify(error=f'Failed to approve service request: {str(e)}'), 500


@app.route('/api/management/service-requests/<int:service_request_id>/reject', methods=['POST'])
@login_required
@role_required('Management')
def reject_management_service_request_api(service_request_id):
    payload = request.get_json(silent=True) or {}
    reason = (payload.get('reason') or '').strip()

    try:
        cur = mysql.connection.cursor()
        cur.execute(
            """
            SELECT service_request_id,
                   requested_notes,
                   COALESCE(status, 'Pending') AS status
            FROM service_requests
            WHERE service_request_id = %s
            LIMIT 1
            """,
            (service_request_id,)
        )
        row = cur.fetchone()
        if not row:
            cur.close()
            return jsonify(error='Service request not found'), 404

        current_status = (row[2] or 'Pending').strip().lower()
        if current_status != 'pending':
            cur.close()
            return jsonify(error=f'Service request is already {row[2]}'), 400

        if reason:
            existing_notes = row[1] or ''
            merged_notes = existing_notes
            if merged_notes:
                merged_notes += "\n\n"
            merged_notes += f"[Rejected] {reason}"
            cur.execute(
                """
                UPDATE service_requests
                SET status = %s,
                    approved_by = %s,
                    requested_notes = %s
                WHERE service_request_id = %s
                """,
                ('Rejected', current_user.id, merged_notes, service_request_id)
            )
        else:
            cur.execute(
                """
                UPDATE service_requests
                SET status = %s,
                    approved_by = %s
                WHERE service_request_id = %s
                """,
                ('Rejected', current_user.id, service_request_id)
            )

        mysql.connection.commit()
        cur.close()
        return jsonify(
            message='Service request rejected',
            service_request_id=service_request_id,
            status='Rejected'
        )
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        mysql.connection.rollback()
        return jsonify(error=f'Failed to reject service request: {str(e)}'), 500


@app.route('/api/clients', methods=['GET'])
@login_required
@role_required('Management')
def get_clients_api():
    search = request.args.get('search', '').strip()

    base_sql = """
        SELECT c.client_id,
               c.company_name,
               c.account_status,
               c.member_since,
               u.first_name,
               u.last_name,
               u.email,
               u.phone,
               SUM(
                   CASE
                       WHEN cl.location_id IS NOT NULL AND COALESCE(cl.is_active, TRUE) = TRUE THEN 1
                       ELSE 0
                   END
               ) AS active_locations
        FROM clients c
        LEFT JOIN users u ON u.user_id = c.contact_user_id
        LEFT JOIN client_locations cl ON cl.client_id = c.client_id
    """

    params = []
    if search:
        base_sql += """
            WHERE c.company_name LIKE %s
               OR CONCAT(u.first_name, ' ', u.last_name) LIKE %s
               OR u.email LIKE %s
        """
        like_term = f"%{search}%"
        params.extend([like_term, like_term, like_term])

    base_sql += """
        GROUP BY c.client_id, c.company_name, c.account_status, c.member_since,
                 u.first_name, u.last_name, u.email, u.phone
        ORDER BY c.client_id DESC
    """

    try:
        cur = mysql.connection.cursor()
        cur.execute(base_sql, tuple(params))
        rows = cur.fetchall()
        cur.close()

        clients = []
        for row in rows:
            clients.append({
                'client_id': row[0],
                'company_name': row[1] or '',
                'account_status': row[2] or 'Active',
                'member_since': row[3].isoformat() if row[3] else None,
                'contact_name': ((row[4] or '') + ' ' + (row[5] or '')).strip(),
                'contact_email': row[6] or '',
                'contact_phone': row[7] or '',
                'active_locations': int(row[8] or 0)
            })

        return jsonify(clients)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load clients: {str(e)}'), 500


@app.route('/api/clients/<int:client_id>/locations', methods=['GET'])
@login_required
@role_required('Management')
def get_client_locations_for_management_api(client_id):
    try:
        cur = mysql.connection.cursor()
        cur.execute(
            """
            SELECT cl.location_id,
                   cl.location_name,
                   a.street_1,
                   a.city,
                   a.state,
                   a.zip_code,
                   COALESCE(cl.is_active, TRUE) AS is_active
            FROM client_locations cl
            JOIN addresses a ON a.address_id = cl.address_id
            WHERE cl.client_id = %s
            ORDER BY cl.location_id DESC
            """,
            (client_id,)
        )
        rows = cur.fetchall()
        cur.close()

        locations = []
        for row in rows:
            locations.append({
                'location_id': row[0],
                'location_name': row[1] or '',
                'street_1': row[2] or '',
                'city': row[3] or '',
                'state': row[4] or '',
                'zip_code': row[5] or '',
                'is_active': bool(row[6])
            })

        return jsonify(locations)
    except Exception as e:
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f'Failed to load client locations: {str(e)}'), 500

# ========================
# AVAILABILITY ENDPOINTS
# ========================

def normalize_week_start_date(date_str):
    """Normalize any date string to the Monday of that week (YYYY-MM-DD)."""
    try:
        parsed = datetime.strptime(date_str, '%Y-%m-%d').date()
        monday = parsed - timedelta(days=parsed.weekday())
        return monday.isoformat()
    except Exception:
        return None


def ensure_employee_record(cur, user_id, job_title='Staff'):
    """Return employee_id for user; create a collision-safe employee record if missing."""
    cur.execute("SELECT employee_id FROM employees WHERE user_id = %s", (user_id,))
    emp_result = cur.fetchone()
    if emp_result:
        return emp_result[0]

    # First try deterministic code by user id.
    base_code = 'EMP{:03d}'.format(int(user_id))
    candidate_code = base_code
    suffix = 1

    # Guarantee unique employee_code even if historical/manual data already used it.
    while True:
        cur.execute("SELECT 1 FROM employees WHERE employee_code = %s LIMIT 1", (candidate_code,))
        if not cur.fetchone():
            break
        candidate_code = f"{base_code}-{suffix}"
        suffix += 1

    cur.execute(
        """
        INSERT INTO employees (user_id, employee_code, job_title)
        VALUES (%s, %s, %s)
        """,
        (user_id, candidate_code, job_title)
    )
    return cur.lastrowid

# --- Save Availability ---
@app.route('/availability', methods=['POST'])
@api_login_required
def save_availability():
    try:
        if not request.is_json:
            return jsonify(error="Request must be JSON"), 400
            
        data = request.get_json()
        
        # Get/create current user's employee_id
        cur = mysql.connection.cursor()
        employee_id = ensure_employee_record(cur, current_user.id, 'Staff')
        
        # Save availability for each day
        week_start_date = data.get('week_start_date')
        if not week_start_date:
            cur.close()
            return jsonify(error="week_start_date is required"), 400
        week_start_date = normalize_week_start_date(week_start_date)
        if not week_start_date:
            cur.close()
            return jsonify(error="week_start_date must be YYYY-MM-DD"), 400
            
        availability_data = data.get('availability', {})
        
        if not availability_data:
            cur.close()
            return jsonify(error="availability data is required"), 400
        
        # Process each day
        for day_str, day_data in availability_data.items():
            try:
                day_of_week = int(day_str)
                available_from = day_data.get('from')
                available_to = day_data.get('to')
                is_available = day_data.get('available', False)
                
                # Skip if times are None (unavailable)
                if available_from is None or available_to is None:
                    is_available = False
                    available_from = None
                    available_to = None
                
                # Delete existing entry for this day
                cur.execute(
                    "DELETE FROM employee_availability WHERE employee_id = %s AND week_start_date = %s AND day_of_week = %s",
                    (employee_id, week_start_date, day_of_week)
                )
                
                # Insert new entry
                cur.execute(
                    """
                    INSERT INTO employee_availability (employee_id, week_start_date, day_of_week, available_from, available_to, is_available)
                    VALUES (%s, %s, %s, %s, %s, %s)
                    """,
                    (employee_id, week_start_date, day_of_week, available_from, available_to, is_available)
                )
            except Exception as day_error:
                cur.close()
                return jsonify(error=f"Error processing day {day_str}: {str(day_error)}"), 400
        
        mysql.connection.commit()
        cur.close()
        
        return jsonify(message="Availability saved successfully"), 201
        
    except Exception as e:
        print(f"Error in save_availability: {str(e)}")
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f"Server error: {str(e)}"), 500


# --- Get Availability for Current Staff ---
@app.route('/availability/my', methods=['GET'])
@api_login_required
def get_my_availability():
    try:
        cur = mysql.connection.cursor()
        
        # Get/create current user's employee_id
        employee_id = ensure_employee_record(cur, current_user.id, 'Staff')
        requested_week = request.args.get('week_start_date')
        week_start_date = None
        availability = []

        if requested_week:
            week_start_date = normalize_week_start_date(requested_week)
            if not week_start_date:
                cur.close()
                return jsonify(error="week_start_date must be YYYY-MM-DD"), 400

            cur.execute(
                """
                SELECT day_of_week, available_from, available_to, is_available
                FROM employee_availability
                WHERE employee_id = %s AND week_start_date = %s
                ORDER BY day_of_week
                """,
                (employee_id, week_start_date)
            )
            availability = cur.fetchall()

        # Fallback: if requested week has no data (or no week was requested), use latest saved week.
        if not availability:
            cur.execute(
                """
                SELECT MAX(week_start_date)
                FROM employee_availability
                WHERE employee_id = %s
                """,
                (employee_id,)
            )
            latest_week = cur.fetchone()
            latest_week = latest_week[0] if latest_week else None
            if latest_week:
                week_start_date = str(latest_week)
                cur.execute(
                    """
                    SELECT day_of_week, available_from, available_to, is_available
                    FROM employee_availability
                    WHERE employee_id = %s AND week_start_date = %s
                    ORDER BY day_of_week
                    """,
                    (employee_id, week_start_date)
                )
                availability = cur.fetchall()

        cur.close()
        
        availability_dict = {}
        for day_of_week, from_time, to_time, is_available in availability:
            from_str = None
            to_str = None
            
            if from_time:
                if hasattr(from_time, 'strftime'):
                    from_str = from_time.strftime('%H:%M')
                else:
                    from_str = str(from_time)
            
            if to_time:
                if hasattr(to_time, 'strftime'):
                    to_str = to_time.strftime('%H:%M')
                else:
                    to_str = str(to_time)
            
            availability_dict[str(day_of_week)] = {
                'from': from_str,
                'to': to_str,
                'available': bool(is_available) if is_available is not None else False
            }
        
        return jsonify({
            'week_start_date': week_start_date,
            'availability': availability_dict
        })
    except Exception as e:
        print(f"Error in get_my_availability: {str(e)}")
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f"Server error: {str(e)}"), 500


# --- Get Availability for Specific Employee (for Management) ---
@app.route('/availability/employee/<int:employee_id>', methods=['GET'])
@api_login_required
def get_employee_availability(employee_id):
    try:
        cur = mysql.connection.cursor()

        # Accept either employee_id or user_id for robustness.
        resolved_employee_id = employee_id
        cur.execute("SELECT employee_id FROM employees WHERE employee_id = %s", (employee_id,))
        existing_emp = cur.fetchone()
        if not existing_emp:
            cur.execute("SELECT employee_id FROM employees WHERE user_id = %s", (employee_id,))
            mapped_emp = cur.fetchone()
            if mapped_emp:
                resolved_employee_id = mapped_emp[0]
        
        # Only allow Management or the employee themselves to view availability.
        is_management = current_user.role == 'Management'
        is_own_record = False
        if not is_management:
            cur.execute("SELECT employee_id FROM employees WHERE user_id = %s", (current_user.id,))
            current_emp = cur.fetchone()
            is_own_record = bool(current_emp and current_emp[0] == resolved_employee_id)
        
        if not (is_management or is_own_record):
            return jsonify(error="Forbidden: you can only view your own availability or be a manager"), 403
        
        requested_week = request.args.get('week_start_date')
        week_start_date = None
        availability = []

        if requested_week:
            week_start_date = normalize_week_start_date(requested_week)
            if not week_start_date:
                cur.close()
                return jsonify(error="week_start_date must be YYYY-MM-DD"), 400

            cur.execute(
                """
                SELECT day_of_week, available_from, available_to, is_available
                FROM employee_availability
                WHERE employee_id = %s AND week_start_date = %s
                ORDER BY day_of_week
                """,
                (resolved_employee_id, week_start_date)
            )
            availability = cur.fetchall()

        # Fallback: if requested week has no data (or no week was requested), use latest saved week.
        if not availability:
            cur.execute(
                """
                SELECT MAX(week_start_date)
                FROM employee_availability
                WHERE employee_id = %s
                """,
                (resolved_employee_id,)
            )
            latest_week = cur.fetchone()
            latest_week = latest_week[0] if latest_week else None
            if latest_week:
                week_start_date = str(latest_week)
                cur.execute(
                    """
                    SELECT day_of_week, available_from, available_to, is_available
                    FROM employee_availability
                    WHERE employee_id = %s AND week_start_date = %s
                    ORDER BY day_of_week
                    """,
                    (resolved_employee_id, week_start_date)
                )
                availability = cur.fetchall()

        cur.close()
        
        availability_dict = {}
        for day_of_week, from_time, to_time, is_available in availability:
            from_str = None
            to_str = None
            
            if from_time:
                if hasattr(from_time, 'strftime'):
                    from_str = from_time.strftime('%H:%M')
                else:
                    from_str = str(from_time)
            
            if to_time:
                if hasattr(to_time, 'strftime'):
                    to_str = to_time.strftime('%H:%M')
                else:
                    to_str = str(to_time)
            
            availability_dict[str(day_of_week)] = {
                'from': from_str,
                'to': to_str,
                'available': bool(is_available) if is_available is not None else False
            }
        
        return jsonify({
            'week_start_date': week_start_date,
            'availability': availability_dict
        })
    except Exception as e:
        print(f"Error in get_employee_availability: {str(e)}")
        if 'cur' in locals():
            cur.close()
        return jsonify(error=f"Server error: {str(e)}"), 500


# ========================
# STAFF API ENDPOINTS
# ========================

@app.route('/staff/schedule/events', methods=['GET'])
@api_login_required
def staff_schedule_events():
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT employee_id FROM employees WHERE user_id = %s", (current_user.id,))
        emp_row = cur.fetchone()
        if not emp_row:
            cur.close()
            return jsonify(events=[])
        employee_id = emp_row[0]

        start_date = request.args.get('start_date')
        end_date = request.args.get('end_date')

        sql = """
            SELECT jo.job_order_id,
                   jo.title,
                   jo.scheduled_date,
                   jo.start_time,
                   jo.end_time,
                   jo.status
            FROM job_orders jo
            WHERE jo.assigned_employee_id = %s
        """
        params = [employee_id]
        if start_date:
            sql += " AND jo.scheduled_date >= %s"
            params.append(start_date)
        if end_date:
            sql += " AND jo.scheduled_date <= %s"
            params.append(end_date)
        sql += " ORDER BY jo.scheduled_date, jo.start_time"

        cur.execute(sql, tuple(params))
        rows = cur.fetchall()
        cur.close()

        events = []
        for row in rows:
            _, title, sched_date, start_t, end_t, status = row
            if not sched_date:
                continue
            date_str = sched_date.isoformat() if hasattr(sched_date, 'isoformat') else str(sched_date)

            def time_to_str(t):
                if t is None:
                    return None
                if hasattr(t, 'seconds'):
                    total = int(t.seconds)
                    h, m, s = total // 3600, (total % 3600) // 60, total % 60
                    return f'{h:02d}:{m:02d}:{s:02d}'
                return str(t)

            start_str = date_str + 'T' + time_to_str(start_t) if start_t else date_str
            end_str = date_str + 'T' + time_to_str(end_t) if end_t else None

            event = {
                'title': title or 'Job Order',
                'start': start_str,
                'extendedProps': {'type': 'order', 'status': status or 'Scheduled'}
            }
            if end_str:
                event['end'] = end_str
            events.append(event)

        return jsonify(events=events)
    except Exception as e:
        print(f'Error in staff_schedule_events: {e}')
        if 'cur' in locals():
            cur.close()
        return jsonify(error=str(e)), 500


@app.route('/staff/skills/my', methods=['GET'])
@api_login_required
def get_my_skills():
    try:
        cur = mysql.connection.cursor()
        employee_id = ensure_employee_record(cur, current_user.id)
        mysql.connection.commit()
        cur.execute("SELECT skill_name FROM employee_skills WHERE employee_id = %s ORDER BY skill_id", (employee_id,))
        rows = cur.fetchall()
        cur.close()
        return jsonify(skills=[r[0] for r in rows])
    except Exception as e:
        print(f'Error in get_my_skills: {e}')
        if 'cur' in locals():
            cur.close()
        return jsonify(error=str(e)), 500


@app.route('/staff/skills/my', methods=['PUT'])
@api_login_required
def save_my_skills():
    try:
        data = request.get_json() or {}
        skills = [s.strip() for s in (data.get('skills') or []) if isinstance(s, str) and s.strip()]
        cur = mysql.connection.cursor()
        employee_id = ensure_employee_record(cur, current_user.id)
        cur.execute("DELETE FROM employee_skills WHERE employee_id = %s", (employee_id,))
        for skill in skills:
            cur.execute("INSERT INTO employee_skills (employee_id, skill_name) VALUES (%s, %s)", (employee_id, skill))
        mysql.connection.commit()
        cur.close()
        return jsonify(skills=skills)
    except Exception as e:
        print(f'Error in save_my_skills: {e}')
        if 'cur' in locals():
            cur.close()
        return jsonify(error=str(e)), 500


@app.route('/staff/tasks/options', methods=['GET'])
@api_login_required
def staff_task_options():
    access_error = require_staff_portal_access()
    if access_error:
        return access_error
    try:
        cur = mysql.connection.cursor()
        cur.execute("SELECT employee_id FROM employees WHERE user_id = %s", (current_user.id,))
        emp_row = cur.fetchone()
        if not emp_row:
            cur.close()
            return jsonify(tasks=[])
        employee_id = emp_row[0]
        cur.execute("""
            SELECT t.task_id, t.task_name, jo.scheduled_date
            FROM tasks t
            JOIN job_orders jo ON jo.job_order_id = t.job_order_id
            WHERE t.assigned_employee_id = %s
            ORDER BY jo.scheduled_date DESC, t.task_id DESC
        """, (employee_id,))
        rows = cur.fetchall()
        cur.close()
        tasks = []
        for task_id, task_name, sched_date in rows:
            label = task_name or f'Task #{task_id}'
            if sched_date:
                if hasattr(sched_date, 'year') and hasattr(sched_date, 'month') and hasattr(sched_date, 'day'):
                    date_s = f"{sched_date.month}/{sched_date.day}/{str(sched_date.year)[-2:]}"
                else:
                    date_s = str(sched_date)
                label = f'{label} ({date_s})'
            tasks.append({'id': task_id, 'label': label})
        return jsonify(tasks=tasks)
    except Exception as e:
        print(f'Error in staff_task_options: {e}')
        if 'cur' in locals():
            cur.close()
        return jsonify(error=str(e)), 500


def resolve_inventory_item_reference(cur, item_id=None, item_name='', allow_unlisted=False):
    if item_id not in (None, ''):
        try:
            item_id = int(item_id)
        except Exception:
            return None, 'item_id must be numeric'

        cur.execute(
            """
            SELECT item_id,
                   item_name,
                   COALESCE(unit_label, 'units') AS unit_label
            FROM inventory_items
            WHERE item_id = %s
              AND COALESCE(is_active, TRUE) = TRUE
            LIMIT 1
            """,
            (item_id,)
        )
        row = cur.fetchone()
        if not row:
            return None, 'Selected inventory item was not found or is inactive'
        return {
            'item_id': row[0],
            'item_name': row[1] or '',
            'unit_label': row[2] or 'units'
        }, None

    normalized_name = (item_name or '').strip()
    if not normalized_name:
        return None, 'Item name is required'

    cur.execute(
        """
        SELECT item_id,
               item_name,
               COALESCE(unit_label, 'units') AS unit_label
        FROM inventory_items
        WHERE COALESCE(is_active, TRUE) = TRUE
          AND LOWER(TRIM(item_name)) = LOWER(TRIM(%s))
        LIMIT 1
        """,
        (normalized_name,)
    )
    row = cur.fetchone()
    if row:
        return {
            'item_id': row[0],
            'item_name': row[1] or normalized_name,
            'unit_label': row[2] or 'units'
        }, None

    if allow_unlisted:
        return {
            'item_id': None,
            'item_name': normalized_name,
            'unit_label': 'units'
        }, None

    return None, f'Item "{normalized_name}" is not in active inventory'


@app.route('/staff/material-requests', methods=['POST'])
@api_login_required
def submit_material_request():
    access_error = require_staff_portal_access()
    if access_error:
        return access_error
    try:
        data = request.get_json() or {}
        item_name = (data.get('item') or '').strip()
        item_id = data.get('item_id')
        quantity_raw = data.get('quantity')
        note = (data.get('note') or '').strip()
        task_id = data.get('task_id') or None

        try:
            quantity = float(quantity_raw)
        except Exception:
            return jsonify(error='Quantity must be greater than zero'), 400
        if quantity <= 0:
            return jsonify(error='Quantity must be greater than zero'), 400

        cur = mysql.connection.cursor()
        employee_id = ensure_employee_record(cur, current_user.id)
        mysql.connection.commit()

        if task_id:
            try:
                task_id = int(task_id)
            except Exception:
                cur.close()
                return jsonify(error='task_id must be numeric when provided'), 400

            cur.execute(
                """
                SELECT task_id
                FROM tasks
                WHERE task_id = %s
                  AND assigned_employee_id = %s
                """,
                (task_id, employee_id)
            )
            if not cur.fetchone():
                cur.close()
                return jsonify(error='Task not found for current staff member'), 404

        resolved_item, item_error = resolve_inventory_item_reference(
            cur,
            item_id=item_id,
            item_name=item_name,
            allow_unlisted=True
        )
        if item_error:
            cur.close()
            return jsonify(error=item_error), 400

        # Generate unique request code
        request_code = f"MR-{datetime.now().strftime('%Y%m%d%H%M%S')}-{employee_id}-{random.randint(10, 99)}"
        detail_note = f"Requested Item: {resolved_item['item_name']} | Qty: {quantity:g} {resolved_item['unit_label']}"
        full_note = detail_note if not note else f"{detail_note}. {note}"

        cur.execute("""
            INSERT INTO material_requests (request_code, employee_id, task_id, note, status, created_at)
            VALUES (%s, %s, %s, %s, 'Pending', NOW())
        """, (request_code, employee_id, task_id, full_note))
        request_id = cur.lastrowid

        cur.execute("""
            INSERT INTO material_request_items (
                material_request_id,
                item_id,
                quantity_requested,
                requested_item_name,
                requested_unit_label
            )
            VALUES (%s, %s, %s, %s, %s)
        """, (
            request_id,
            resolved_item.get('item_id'),
            quantity,
            resolved_item['item_name'],
            resolved_item['unit_label']
        ))

        mysql.connection.commit()
        cur.close()
        return jsonify(
            message='Request submitted successfully',
            request_code=request_code,
            material_request_id=request_id
        ), 201
    except Exception as e:
        print(f'Error in submit_material_request: {e}')
        if 'cur' in locals():
            cur.close()
        mysql.connection.rollback()
        return jsonify(error=str(e)), 500


@app.route('/staff/material-usage', methods=['POST'])
@api_login_required
def submit_material_usage():
    access_error = require_staff_portal_access()
    if access_error:
        return access_error
    try:
        data = request.get_json() or {}
        task_id = data.get('task_id')
        items = data.get('items') or []

        if task_id in (None, ''):
            return jsonify(error='Task ID is required'), 400
        if not items:
            return jsonify(error='At least one item is required'), 400

        try:
            task_id = int(task_id)
        except Exception:
            return jsonify(error='task_id must be numeric'), 400

        cur = mysql.connection.cursor()
        employee_id = ensure_employee_record(cur, current_user.id)
        mysql.connection.commit()

        cur.execute(
            """
            SELECT task_id
            FROM tasks
            WHERE task_id = %s
              AND assigned_employee_id = %s
            """,
            (task_id, employee_id)
        )
        if not cur.fetchone():
            cur.close()
            return jsonify(error='Task not found for current staff member'), 404

        resolved_entries = []
        validation_errors = []

        for idx, entry in enumerate(items):
            item_name = (entry.get('item') or '').strip()
            item_id = entry.get('item_id')
            quantity_raw = entry.get('quantity')

            # Ignore empty rows from dynamic forms.
            if item_id in (None, '') and not item_name and quantity_raw in (None, ''):
                continue

            try:
                quantity = float(quantity_raw)
            except Exception:
                validation_errors.append(f'Row {idx + 1}: quantity must be a number')
                continue

            if quantity <= 0:
                validation_errors.append(f'Row {idx + 1}: quantity must be greater than zero')
                continue

            resolved_item, item_error = resolve_inventory_item_reference(
                cur,
                item_id=item_id,
                item_name=item_name,
                allow_unlisted=False
            )
            if item_error:
                validation_errors.append(f'Row {idx + 1}: {item_error}')
                continue

            resolved_entries.append({
                'item_id': resolved_item['item_id'],
                'item_name': resolved_item['item_name'],
                'quantity': quantity
            })

        if validation_errors:
            cur.close()
            return jsonify(error='; '.join(validation_errors)), 400

        if not resolved_entries:
            cur.close()
            return jsonify(error='At least one valid material row is required'), 400

        cur.execute("""
            INSERT INTO material_usage_logs (task_id, employee_id, logged_at)
            VALUES (%s, %s, NOW())
        """, (task_id, employee_id))
        log_id = cur.lastrowid

        for entry in resolved_entries:
            cur.execute("""
                INSERT INTO material_usage_items (usage_log_id, item_id, quantity_used)
                VALUES (%s, %s, %s)
            """, (log_id, entry['item_id'], entry['quantity']))
            # Deduct from inventory while preventing negative stock.
            cur.execute("""
                UPDATE inventory_items
                SET quantity_on_hand = GREATEST(0, quantity_on_hand - %s)
                WHERE item_id = %s
            """, (entry['quantity'], entry['item_id']))

        mysql.connection.commit()
        cur.close()
        return jsonify(
            message='Usage log submitted successfully',
            usage_log_id=log_id,
            submitted_items=len(resolved_entries)
        ), 201
    except Exception as e:
        print(f'Error in submit_material_usage: {e}')
        if 'cur' in locals():
            cur.close()
        mysql.connection.rollback()
        return jsonify(error=str(e)), 500


# ========================
# DATABASE HELPER
# ========================

def run_schema_file():
    with open(SCHEMA_PATH, 'r', encoding='utf-8') as sql_file:
        sql_text = sql_file.read()

    cur = mysql.connection.cursor()
    statements = [stmt.strip() for stmt in sql_text.split(';') if stmt.strip()]

    for statement in statements:
        cur.execute(statement)

    mysql.connection.commit()
    cur.close()


@app.route('/init-db', methods=['POST'])
@login_required
@role_required('Management')
def init_db():
    try:
        run_schema_file()
        return jsonify(message="Database initialized from Planted_Database.sql"), 200
    except Exception as e:
        return jsonify(error=f"Database initialization failed: {str(e)}"), 500


@app.cli.command('init-db')
def init_db_command():
    """Initialize the MySQL schema from Planted_Database.sql."""
    run_schema_file()
    click.echo('Database initialized from Planted_Database.sql')


# ========================
# RUN APP
# ========================

if __name__ == '__main__':
    port = int(os.environ.get('PORT', 5001))
    app.run(debug=True, host='127.0.0.1', port=port)
