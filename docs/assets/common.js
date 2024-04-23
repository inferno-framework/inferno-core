$(document).ready(function () {
  $(window).scroll(function () {
    if ($(window).scrollTop() > 10) {
      $('.navbar').addClass('scrolled');
    } else {
      $('.navbar').removeClass('scrolled');
    }
  });
});


/* autorefresh on change */
let previousResponse = null;

function checkForChanges() {
  // Call your backend API to check for changes
  fetch('change.html')
    .then(response => response.text())
    .then(data => {
      if (previousResponse !== null && data !== previousResponse) {
        // The response has changed, refresh the page
        window.location.reload();
      } else {
        // The response is the same, update the previous response
        previousResponse = data;
      }
    })
    .catch(error => {
      console.error('Error checking for changes:', error);
    });
}

window.jtd = window;

jtd.addEvent = function (el, type, handler) {
  if (el.attachEvent) el.attachEvent('on' + type, handler); else el.addEventListener(type, handler);
};
jtd.removeEvent = function (el, type, handler) {
  if (el.detachEvent) el.detachEvent('on' + type, handler); else el.removeEventListener(type, handler);
};
jtd.onReady = function (ready) {
  // in case the document is already rendered
  if (document.readyState != 'loading') ready();
  // modern browsers
  else if (document.addEventListener) document.addEventListener('DOMContentLoaded', ready);
  // IE <= 8
  else document.attachEvent('onreadystatechange', function () {
    if (document.readyState == 'complete') ready();
  });
};