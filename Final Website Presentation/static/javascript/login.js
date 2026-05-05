document.addEventListener('DOMContentLoaded', function() {
  const form = document.querySelector('.frame-1');
  const emailInput = document.getElementById('email');
  const passwordInput = document.getElementById('password');
  const emailError = document.getElementById('email-error');
  const passwordError = document.getElementById('password-error');
  const credentialsError = document.getElementById('credentials-error');

  if (!form || !emailInput || !passwordInput) {
    console.error('Form elements not found');
    return;
  }

  // Clear error messages when user starts typing
  emailInput.addEventListener('input', function() {
    emailError.textContent = '';
    emailError.classList.remove('show');
  });

  passwordInput.addEventListener('input', function() {
    passwordError.textContent = '';
    passwordError.classList.remove('show');
  });

  // Form submission validation
  form.addEventListener('submit', function(e) {
    e.preventDefault();
    
    // Clear previous errors
    emailError.textContent = '';
    emailError.classList.remove('show');
    passwordError.textContent = '';
    passwordError.classList.remove('show');
    credentialsError.textContent = '';
    credentialsError.classList.remove('show');

    let hasErrors = false;

    // Validate email
    if (!emailInput.value.trim()) {
      emailError.textContent = 'Please enter an email address';
      emailError.classList.add('show');
      hasErrors = true;
    } else if (!isValidEmail(emailInput.value)) {
      emailError.textContent = 'Please enter a valid email address';
      emailError.classList.add('show');
      hasErrors = true;
    }

    // Validate password
    if (!passwordInput.value.trim()) {
      passwordError.textContent = 'Please enter a password';
      passwordError.classList.add('show');
      hasErrors = true;
    }

    // If there are validation errors, don't submit
    if (hasErrors) {
      return false;
    }

    // Otherwise, submit the form
    form.submit();
  });

  // Helper function to validate email format
  function isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email);
  }
});

