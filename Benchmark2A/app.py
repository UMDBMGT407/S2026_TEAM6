from flask import Flask, render_template, request, redirect, url_for, abort, jsonify
from flask_login import LoginManager, UserMixin, login_user, login_required, logout_user, current_user
from flask_mysqldb import MySQL
from werkzeug.security import generate_password_hash, check_password_hash
from functools import wraps
import os
import click

# ========================
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


def role_required(*roles):
    def wrapper(fn):
        @wraps(fn)
        def decorated_view(*args, **kwargs):
            if not current_user.is_authenticated:
                return abort(403)
            if is_admin():
                return fn(*args, **kwargs)
            if current_user.role not in roles:
                return abort(403)
            return fn(*args, **kwargs)
        return decorated_view
    return wrapper

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
def clients_page():
    return render_template('clients.html')


@app.route('/scheduling.html')
@login_required
def scheduling_page():
    return render_template('scheduling.html')


@app.route('/suppliers.html')
@login_required
def suppliers_page():
    return render_template('suppliers.html')


@app.route('/inventory.html')
@login_required
def inventory_page():
    return render_template('inventory.html')


@app.route('/plant-master.html')
@login_required
def plant_master_page():
    return render_template('plant-master.html')


@app.route('/job-order.html')
@login_required
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
    app.run(debug=True)
