let report =
"""
body {
    background-color: #FAFAFA;
    color: #000000;
    font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif, Apple Color Emoji, Segoe UI Emoji
}

h1 {
    font-size: 3em;
    margin: 0;
}

.report {
    font-size: 15px;
    font-weight: normal;
    margin: auto;
    padding: 30px;
    min-width: 210mm;
    max-width: 610mm;
}

header {
    position: relative;
    width: 100%;
    display: flex;
    align-items: flex-end;
    align-content: stretch;
    text-align: right;
}

.header-item {
    padding: 10px;
    flex: auto;
}

.box {
    border-radius: 8px;
    padding: 15px;
    color: #ffffff;
}

header:after {
    content: "";
    display: flex;
    clear: both;
}

.small {
    font-variant: small-caps;
    font-weight: normal;
}

.strong {
    font-size: 20px;
    font-weight: bolder;
}

.divider {
    display: flex;
    flex-direction: row;
    padding-top: 30px;
}

.divider-content {
    font-variant: small-caps;
    font-size: 20px;
    padding: 0px 30px;
}

.divider:before,
.divider:after {
    content: "";
    flex: 1 1;
    border-bottom: 1px solid #000000;
    margin: auto;
}

table {
    table-layout: fixed;
    border-collapse: collapse;
    width: 100%;
    empty-cells: hide;
    word-wrap: break-word;
}

td,
th {
    border: 1px solid #ddd;
    padding: 8px;
    text-align: center;
}

tr:nth-child(even) {
    background-color: #dfe4ea;
}

tr:nth-child(odd) {
    background-color: #f1f2f6;
}

tr:hover {
    background-color: #ecf5e1;
}

th {
    color: #fff;
    padding-top: 12px;
    padding-bottom: 12px;
    text-align: center;
    background-color: #3498db;
}

.left-aligned {
    text-align: left;
}

.right-aligned {
    text-align: right;
}

.failed {
    height: 30px;
}

.passed {
    height: 30px;
}

.build-error {
    height: 30px;
}

.no-coverage {
    height: 30px;
}

.footer {
    left: 0;
    bottom: 0;
    width: 100%;
    text-align: center;
}

.toggle {
    float: right;
    padding: 5px 0px 10px 0px;
}

.logo {
    padding-bottom: 10px;
    width: 400px;
}

.snapshot-before {
    padding: 8px;
    align-content: stretch;
    background-color: #ffeef0;
    flex: 1;
}

.snapshot-arrow {
    align-self: center;
}

.snapshot-after {
    padding: 8px;
    background-color: #e6ffed;
    flex: 1;
}

.snapshot-changes {
    display: flex;
    justify-content: space-around;
    align-self: center;
    align-content: stretch;
}

.snapshot-changes  {
    align-self: center;
    align-content: stretch;
    width: 100%;
}

@media (prefers-color-scheme: dark) {
    body {
        color: #eee;
        background: #0d1117;
    }
    
    p, span, label, h1 {
        color: #ffffff;
    }
    
    .snapshot-before {
        background-color: rgba(218,54,51,0.2);
    }
    
    .snapshot-after {
        background-color: rgba(46,160,67, 0.2);
    }
    
    .divider:before,
    .divider:after {
        border-bottom: 1px solid #ffffff;
    }
    
    tr:nth-child(even) {
        background-color: #1b2430;
    }
    
    tr:nth-child(odd) {
        background-color: #0d1117;
    }
    
    tr:hover {
        background-color: #293649;
    }
    
    th {
        background-color: #293649;
    }
}
"""