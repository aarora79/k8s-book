// Opens code files in the panel on the right of the page.
//
// Chapter text links each code file to GitHub. When a reader clicks one of
// those links, this script loads the same file from this site instead and
// shows it in the panel, with line numbers. Ctrl-click or Cmd-click still
// opens GitHub in a new tab.

var REPO_PREFIX = "https://github.com/aarora79/k8s-book/blob/main/";
var COPIED_RESET_MS = 2000;

var panelBody = document.getElementById("code-panel-body");
var panelTitle = document.getElementById("code-panel-title");
var copyButton = document.getElementById("code-panel-copy");
var githubLink = document.getElementById("code-panel-github");
var closeButton = document.getElementById("code-panel-close");
var emptyMessage = panelBody.innerHTML;
var currentText = "";
var currentLink = null;


function showMessage(text) {
  panelBody.innerHTML = "";
  var p = document.createElement("p");
  p.className = "code-panel-empty";
  p.textContent = text;
  panelBody.appendChild(p);
}


function showCode(text) {
  // One span per line, so CSS can number the lines.
  var pre = document.createElement("pre");
  var lines = text.replace(/\n$/, "").split("\n");
  for (var i = 0; i < lines.length; i++) {
    var line = document.createElement("span");
    line.className = "code-line";
    line.textContent = lines[i] + "\n";
    pre.appendChild(line);
  }
  panelBody.innerHTML = "";
  panelBody.appendChild(pre);
  panelBody.scrollTop = 0;
}


function openFile(link) {
  var path = link.href.slice(REPO_PREFIX.length);
  var baseUrl = document.body.getAttribute("data-baseurl");

  if (currentLink !== null) {
    currentLink.classList.remove("code-link-active");
  }
  currentLink = link;
  link.classList.add("code-link-active");

  panelTitle.textContent = path.split("/").slice(-2).join("/");
  panelTitle.title = path;
  githubLink.href = link.href;
  githubLink.hidden = false;
  copyButton.hidden = true;
  document.body.classList.add("code-panel-open");
  showMessage("Loading " + path + " ...");

  fetch(baseUrl + "/" + path)
    .then(function (response) {
      if (!response.ok) {
        throw new Error("HTTP " + response.status);
      }
      return response.text();
    })
    .then(function (text) {
      currentText = text;
      copyButton.hidden = false;
      showCode(text);
    })
    .catch(function () {
      showMessage("Could not load " + path + ". Use the GitHub button to read it there.");
    });
}


function closePanel() {
  document.body.classList.remove("code-panel-open");
  if (currentLink !== null) {
    currentLink.classList.remove("code-link-active");
    currentLink = null;
  }
  panelTitle.textContent = "Code";
  panelTitle.title = "";
  githubLink.hidden = true;
  copyButton.hidden = true;
  currentText = "";
  panelBody.innerHTML = emptyMessage;
}


document.addEventListener("click", function (event) {
  var link = event.target.closest("a");
  if (link === null || link.href.indexOf(REPO_PREFIX) !== 0) {
    return;
  }
  if (link.closest(".code-panel") !== null) {
    return;
  }
  if (event.ctrlKey || event.metaKey || event.shiftKey) {
    return;
  }
  event.preventDefault();
  openFile(link);
});

closeButton.addEventListener("click", closePanel);

copyButton.addEventListener("click", function () {
  navigator.clipboard.writeText(currentText).then(function () {
    copyButton.textContent = "Copied";
    setTimeout(function () {
      copyButton.textContent = "Copy";
    }, COPIED_RESET_MS);
  });
});
