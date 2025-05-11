let javascript = """
window.onload = function() {
    setupTheme();

    showHide(false, 'mutation-operators-per-file');
    showHide(false, 'applied-operators');
};

function isSnapshotRow(row) {
    return row && new RegExp("snapshot").test(row.className);
}

function showHide(shouldShow, tableId) {
    var rows = Array.from(document.getElementById(tableId).tBodies[0].rows)
    .filter(row => { return !isSnapshotRow(row); });

    var displayCount = shouldShow ? rows.length : 9;

    showFirstRows(rows, displayCount);
}

function showFirstRows(rows, count) {
    rows.slice(0, count).forEach(row => { row.style.display = "table-row"; });

    const remeaning = Math.max(rows.length - count - 1, 0);

    if (remeaning != 0) {
        rows.slice(-remeaning).forEach(row => { row.style.display = "none"; });
    }
}

function showChange(button) {
    const changes = button.parentElement.parentElement.nextElementSibling.firstElementChild;
    const isHidding = changes.style.display == "table-cell";


    if (isHidding) {
        changes.style.display = "none";
        button.innerHTML = "+";
    } else {
        changes.style.display = "table-cell";
        button.innerHTML = "-";
    }
}

function setupTheme() {
    localStorage.setItem('theme', 'dark');

    localStorage.getItem('theme');

    const toggle = document.getElementById("toggle");
    const theme = window.localStorage.getItem("theme");

    if (theme === "dark") {
        document.body.classList.add("dark");
    }

    toggle.addEventListener("click", () => {
      document.body.classList.toggle("dark");
      if (theme === "dark") {
        window.localStorage.setItem("theme", "light");
      } else window.localStorage.setItem("theme", "dark");
    });
}
"""
