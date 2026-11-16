// Adds a copy button to the top right of every code block on the page.

var COPY_ICON =
  '<svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true">' +
  '<path fill="currentColor" d="M0 6.75C0 5.78.78 5 1.75 5h1.5a.75.75 0 0 1 0 1.5h-1.5a.25.25 0 0 0-.25.25v7.5c0 .14.11.25.25.25h7.5a.25.25 0 0 0 .25-.25v-1.5a.75.75 0 0 1 1.5 0v1.5A1.75 1.75 0 0 1 9.25 16h-7.5A1.75 1.75 0 0 1 0 14.25Z"/>' +
  '<path fill="currentColor" d="M5 1.75C5 .78 5.78 0 6.75 0h7.5C15.22 0 16 .78 16 1.75v7.5A1.75 1.75 0 0 1 14.25 11h-7.5A1.75 1.75 0 0 1 5 9.25Zm1.75-.25a.25.25 0 0 0-.25.25v7.5c0 .14.11.25.25.25h7.5a.25.25 0 0 0 .25-.25v-7.5a.25.25 0 0 0-.25-.25Z"/>' +
  '</svg>';

var CHECK_ICON =
  '<svg viewBox="0 0 16 16" width="16" height="16" aria-hidden="true">' +
  '<path fill="currentColor" d="M13.78 4.22a.75.75 0 0 1 0 1.06l-7.25 7.25a.75.75 0 0 1-1.06 0L2.22 9.28a.75.75 0 0 1 1.06-1.06L6 10.94l6.72-6.72a.75.75 0 0 1 1.06 0Z"/>' +
  '</svg>';

var RESET_AFTER_MS = 2000;


function addCopyButton(block) {
  var code = block.querySelector("pre");
  if (code === null) {
    return;
  }

  var button = document.createElement("button");
  button.className = "copy-button";
  button.type = "button";
  button.title = "Copy";
  button.setAttribute("aria-label", "Copy code");
  button.innerHTML = COPY_ICON;

  button.addEventListener("click", function () {
    navigator.clipboard.writeText(code.innerText).then(function () {
      button.innerHTML = CHECK_ICON;
      button.title = "Copied";
      setTimeout(function () {
        button.innerHTML = COPY_ICON;
        button.title = "Copy";
      }, RESET_AFTER_MS);
    });
  });

  block.appendChild(button);
}


var blocks = document.querySelectorAll("div.highlighter-rouge");
for (var i = 0; i < blocks.length; i++) {
  addCopyButton(blocks[i]);
}
