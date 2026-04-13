from flask import Flask, render_template, request, redirect, url_for, abort, jsonify
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_mysqldb import MySQL
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
from datetime import datetime, timedelta
import os
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
app.config['MYSQL_PASSWORD'] = 'Kkim8889.'
app.config['MYSQL_DB'] = 'user_management'

mysql = MySQL(app)
SCHEMA_PATH = os.path.join(base_dir, 'Planted_Database.sql')

# --- Login Manager ---
login_manager = LoginManager()
login_manager.init_app(app)
login_manager.login_view = 'login'

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
                if request.path.startswith('/availability'):
                    return jsonify(error="Unauthorized - not logged in"), 401
                return redirect(url_for('login'))
            
            # Check if user has required role (Management is admin and can access everything)
            user_role = current_user.role if hasattr(current_user, 'role') else None
            is_management = user_role == 'Management'
            has_required_role = user_role in roles
            
            if not (is_management or has_required_role):
                # Return JSON for API requests, HTML abort for regular requests
                if request.path.startswith('/availability'):
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

# ========================
# ROUTES
# ========================

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
    mysql.connection.commit()

    user_id = cur.lastrowid
    user_name = f"{first_name} {last_name}"
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
def appointments_page():
    return render_template('appointments.html')


@app.route('/service-request.html')
@login_required
def service_request_page():
    return render_template('service-request.html')


@app.route('/invoices.html')
@login_required
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


@app.route('/staff-scheduling-dashboard.html')
@login_required
def staff_scheduling_dashboard_page():
    return render_template('staff-scheduling-dashboard.html')


@app.route('/task-management-dashboard.html')
@login_required
def task_management_dashboard_page():
    return render_template('task-management-dashboard.html')


@app.route('/inventory-dashboard.html')
@login_required
def inventory_dashboard_page():
    return render_template('inventory-dashboard.html')


@app.route('/availability-entry.html')
@login_required
def availability_entry_page():
    return redirect(url_for('staff_scheduling_dashboard_page', modal='availability'))


@app.route('/material-requests.html')
@login_required
def material_requests_page():
    return redirect(url_for('inventory_dashboard_page', modal='request'))


@app.route('/used-material-log.html')
@login_required
def used_material_log_page():
    return redirect(url_for('inventory_dashboard_page', modal='usage'))


@app.route('/job-materials.html')
@login_required
def job_materials_page():
    return redirect(url_for('task_management_dashboard_page', modal='materials'))


@app.route('/contact-client.html')
@login_required
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
            INSERT INTO users (first_name, last_name, email, password, role, phone)
            VALUES (%s, %s, %s, %s, %s, %s)
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
               role
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
            'role': user[3]
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

    cur.execute("DELETE FROM users WHERE user_id = %s", [id])

    mysql.connection.commit()
    cur.close()

    return jsonify(message="User deleted successfully")


# --- Get Employees (Staff only) ---
@app.route('/employees', methods=['GET'])
@login_required
@role_required('Management')
def get_employees():
    cur = mysql.connection.cursor()

    cur.execute(
        """
     SELECT u.user_id,
         CONCAT(u.first_name, ' ', u.last_name) AS name,
         u.email,
         u.phone,
         u.role,
         e.employee_id
     FROM users u
     LEFT JOIN employees e ON e.user_id = u.user_id
     WHERE u.role = 'Staff'
     ORDER BY u.user_id
        """
    )
    employees = cur.fetchall()
    cur.close()

    employee_list = []
    for emp in employees:
        employee_list.append({
            'id': emp[0],
            'name': emp[1],
            'email': emp[2],
            'phone': emp[3],
            'role': emp[4],
            'employee_id': emp[5]
        })

    return jsonify(employee_list)


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


@app.route('/init-db')
def init_db():
    run_schema_file()
    return "Database initialized from Planted_Database.sql"


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
