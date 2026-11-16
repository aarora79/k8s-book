// Opens and closes the sidebar menu on narrow screens.

var menuButton = document.querySelector(".menu-button");
var sidebar = document.getElementById("sidebar");

if (menuButton !== null && sidebar !== null) {
  menuButton.addEventListener("click", function () {
    var isOpen = sidebar.classList.toggle("open");
    menuButton.setAttribute("aria-expanded", isOpen ? "true" : "false");
  });
}
