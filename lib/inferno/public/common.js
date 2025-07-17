/* UTILITIES */

// Show/hide element based on condition
const showElement = (condition, element) => {
  if (condition) {
    element.classList.add('show-item');
    element.classList.remove('hide-item');
  } else {
    element.classList.add('hide-item');
    element.classList.remove('show-item');
  }
};

// Show toast message -- there should only be one at a time, 
//    if this behavior changes then this will need to be updated
const showToast = (message) => {
  const toastElement = document.querySelector('.toast');
  const toast = new bootstrap.Toast(toastElement);
  const toastBody = document.querySelector('.toast-body');
  toastBody.innerHTML = ''; // clear any existing errors
  toastBody.append(message);
  toast.show();
};

$(document).ready(function () {
  const scrollTopTrigger = 0;
  $(window).scroll(function () {
    if ($(window).scrollTop() > scrollTopTrigger) {
      $('.navbar').addClass('scrolled');
    } else {
      $('.navbar').removeClass('scrolled');
    }
  });
  if ($(window).scrollTop() > scrollTopTrigger) {
    $('.navbar').addClass('scrolled');
  } else {
    $('.navbar').removeClass('scrolled');
  }
});

document.addEventListener('DOMContentLoaded', function () {
  var tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
  var tooltipList = tooltipTriggerList.map(function (tooltipTriggerEl) {
    return new bootstrap.Tooltip(tooltipTriggerEl);
  });
});


