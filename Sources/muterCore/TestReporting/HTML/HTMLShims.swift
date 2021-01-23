let css = normalizeCSS + reportCSS

private let normalizeCSS =
    """
    /*! normalize.css v8.0.1 | MIT License | github.com/necolas/normalize.css */

    /* Document
    ========================================================================== */

    /**
    * 1. Correct the line height in all browsers.
    * 2. Prevent adjustments of font size after orientation changes in iOS.
    */

       html {
           line-height: 1.15;
           /* 1 */
           -webkit-text-size-adjust: 100%;
           /* 2 */
       }

       /* Sections
      ========================================================================== */

       /**
    * Remove the margin in all browsers.
    */

       body {
           margin: 0;
       }

       /**
    * Render the `main` element consistently in IE.
    */

       main {
           display: block;
       }

       /**
    * Correct the font size and margin on `h1` elements within `section` and
    * `article` contexts in Chrome, Firefox, and Safari.
    */

       h1 {
           font-size: 2em;
           margin: 0.67em 0;
       }

       /* Grouping content
      ========================================================================== */

       /**
    * 1. Add the correct box sizing in Firefox.
    * 2. Show the overflow in Edge and IE.
    */

       hr {
           box-sizing: content-box;
           /* 1 */
           height: 0;
           /* 1 */
           overflow: visible;
           /* 2 */
       }

       /**
    * 1. Correct the inheritance and scaling of font size in all browsers.
    * 2. Correct the odd `em` font sizing in all browsers.
    */

       pre {
           font-family: monospace, monospace;
           /* 1 */
           font-size: 1em;
           /* 2 */
       }

       /* Text-level semantics
      ========================================================================== */

       /**
    * Remove the gray background on active links in IE 10.
    */

       a {
           background-color: transparent;
       }

       /**
    * 1. Remove the bottom border in Chrome 57-
    * 2. Add the correct text decoration in Chrome, Edge, IE, Opera, and Safari.
    */

       abbr[title] {
           border-bottom: none;
           /* 1 */
           text-decoration: underline;
           /* 2 */
           text-decoration: underline dotted;
           /* 2 */
       }

       /**
    * Add the correct font weight in Chrome, Edge, and Safari.
    */

       b,
       strong {
           font-weight: bolder;
       }

       /**
    * 1. Correct the inheritance and scaling of font size in all browsers.
    * 2. Correct the odd `em` font sizing in all browsers.
    */

       code,
       kbd,
       samp {
           font-family: monospace, monospace;
           /* 1 */
           font-size: 1em;
           /* 2 */
       }

       /**
    * Add the correct font size in all browsers.
    */

       small {
           font-size: 80%;
       }

       /**
    * Prevent `sub` and `sup` elements from affecting the line height in
    * all browsers.
    */

       sub,
       sup {
           font-size: 75%;
           line-height: 0;
           position: relative;
           vertical-align: baseline;
       }

       sub {
           bottom: -0.25em;
       }

       sup {
           top: -0.5em;
       }

       /* Embedded content
      ========================================================================== */

       /**
    * Remove the border on images inside links in IE 10.
    */

       img {
           border-style: none;
       }

       /* Forms
      ========================================================================== */

       /**
    * 1. Change the font styles in all browsers.
    * 2. Remove the margin in Firefox and Safari.
    */

       button,
       input,
       optgroup,
       select,
       textarea {
           font-family: inherit;
           /* 1 */
           font-size: 100%;
           /* 1 */
           line-height: 1.15;
           /* 1 */
           margin: 0;
           /* 2 */
       }

       /**
    * Show the overflow in IE.
    * 1. Show the overflow in Edge.
    */

       button,
       input {
           /* 1 */
           overflow: visible;
       }

       /**
    * Remove the inheritance of text transform in Edge, Firefox, and IE.
    * 1. Remove the inheritance of text transform in Firefox.
    */

       button,
       select {
           /* 1 */
           text-transform: none;
       }

       /**
    * Correct the inability to style clickable types in iOS and Safari.
    */

       button,
       [type="button"],
       [type="reset"],
       [type="submit"] {
           -webkit-appearance: button;
       }

       /**
    * Remove the inner border and padding in Firefox.
    */

       button::-moz-focus-inner,
       [type="button"]::-moz-focus-inner,
       [type="reset"]::-moz-focus-inner,
       [type="submit"]::-moz-focus-inner {
           border-style: none;
           padding: 0;
       }

       /**
    * Restore the focus styles unset by the previous rule.
    */

       button:-moz-focusring,
       [type="button"]:-moz-focusring,
       [type="reset"]:-moz-focusring,
       [type="submit"]:-moz-focusring {
           outline: 1px dotted ButtonText;
       }

       /**
    * Correct the padding in Firefox.
    */

       fieldset {
           padding: 0.35em 0.75em 0.625em;
       }

       /**
    * 1. Correct the text wrapping in Edge and IE.
    * 2. Correct the color inheritance from `fieldset` elements in IE.
    * 3. Remove the padding so developers are not caught out when they zero out
    *    `fieldset` elements in all browsers.
    */

       legend {
           box-sizing: border-box;
           /* 1 */
           color: inherit;
           /* 2 */
           display: table;
           /* 1 */
           max-width: 100%;
           /* 1 */
           padding: 0;
           /* 3 */
           white-space: normal;
           /* 1 */
       }

       /**
    * Add the correct vertical alignment in Chrome, Firefox, and Opera.
    */

       progress {
           vertical-align: baseline;
       }

       /**
    * Remove the default vertical scrollbar in IE 10+.
    */

       textarea {
           overflow: auto;
       }

       /**
    * 1. Add the correct box sizing in IE 10.
    * 2. Remove the padding in IE 10.
    */

       [type="checkbox"],
       [type="radio"] {
           box-sizing: border-box;
           /* 1 */
           padding: 0;
           /* 2 */
       }

       /**
    * Correct the cursor style of increment and decrement buttons in Chrome.
    */

       [type="number"]::-webkit-inner-spin-button,
       [type="number"]::-webkit-outer-spin-button {
           height: auto;
       }

       /**
    * 1. Correct the odd appearance in Chrome and Safari.
    * 2. Correct the outline style in Safari.
    */

       [type="search"] {
           -webkit-appearance: textfield;
           /* 1 */
           outline-offset: -2px;
           /* 2 */
       }

       /**
    * Remove the inner padding in Chrome and Safari on macOS.
    */

       [type="search"]::-webkit-search-decoration {
           -webkit-appearance: none;
       }

       /**
    * 1. Correct the inability to style clickable types in iOS and Safari.
    * 2. Change font properties to `inherit` in Safari.
    */

       ::-webkit-file-upload-button {
           -webkit-appearance: button;
           /* 1 */
           font: inherit;
           /* 2 */
       }

       /* Interactive
      ========================================================================== */

       /*
    * Add the correct display in Edge, IE 10+, and Firefox.
    */

       details {
           display: block;
       }

       /*
    * Add the correct display in all browsers.
    */

       summary {
           display: list-item;
       }

       /* Misc
      ========================================================================== */

       /**
    * Add the correct display in IE 10+.
    */

       template {
           display: none;
       }

       /**
    * Add the correct display in IE 10.
    */

       [hidden] {
           display: none;
       }
    """

private let reportCSS =
    """
        body {
            background-color: #FAFAFA;
            font-family: -apple-system, BlinkMacSystemFont, Segoe UI, Helvetica, Arial, sans-serif, Apple Color Emoji, Segoe UI Emoji
        }

        h1 {
            font-size: 3em;
            margin: 0;
        }

        .report {
            color: #000000;
            font-size: 15px;
            font-family: 'Roboto';
            font-weight: normal;
            margin: auto;
            padding: 30px;
            max-width: 210mm;
        }

        header {
            position: relative;
            width: 100%;
            display: inline-flex;
            flex-wrap: nowrap;
            justify-content: flex-start;
            align-items: flex-end;
            align-content: stretch;
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
            color: #000000;
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
            border-bottom: 1px solid #000;
            margin: auto;
        }

        table {
            border-collapse: collapse;
            width: 100%;
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
            padding-top: 12px;
            padding-bottom: 12px;
            color: #ffffff;
            text-align: center;
            background-color: #3498db;
        }

        .failed {
            color: #F70000;
            height: 20px;
        }

        .passed {
            color: #50A000;
            height: 20px;
        }

        .build-error {
            color: #1D2535;
            height: 20px;
        }

        .footer {
            position: fixed;
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

    .mutation-snapshot-after,
    .mutation-snapshot-before {
        display: none;
        text-align: left;
        padding-left: 20px;
        background-color: #FFC1C1;
    }

    .mutation-snapshot-after {
        background-color: #BFFFCB;
    }

    .mutation-snapshot-after-row {
        border: solid 2px #00D200;
    }

    .mutation-snapshot-before-row {
        border: solid 2px #DE0D00;
    }
    """

let javascript =
    """
    window.onload = function() {
        showHide(false, 'mutation-operators-per-file');
        showHide(false, 'applied-operators');
    };

    function isSnapshotRow(row) {
        return row && new RegExp("snapshot").test(row.className);
    }

    function showHide(shouldShow, tableId) {
        var rows = Array.from(document.getElementById(tableId).rows)
                        .filter(row => { return !isSnapshotRow(row); });

        var displayCount = shouldShow ? rows.length : 10;

        showFirstRows(rows, displayCount);
    }

    function showHide(shouldShow, tableId) {
        var rows = Array.from(document.getElementById(tableId).tBodies[0].rows)
        .filter(row => { return !isSnapshotRow(row); });
        
        var displayCount = shouldShow ? rows.length : 10;
        
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
        var beforeElement = button.parentElement.parentElement.nextElementSibling.firstElementChild;
        var afterElement = button.parentElement.parentElement.nextElementSibling.nextElementSibling.lastElementChild;

        if (beforeElement.style.display == "table-cell") {
            beforeElement.style.display = "none";
            afterElement.style.display = "none";
            button.innerHTML = "+";
        } else {
            beforeElement.style.display = "table-cell";
            afterElement.style.display = "table-cell";
            button.innerHTML = "-";
        }
    }
    """

let muterLogo = 
    """
    <svg viewBox="0 0 1121 354" width="100%">
      <style>
        .a {
        fill: #1e2434
        }
    
        .b,
        .c {
        fill-opacity: .4;
        fill: #fff
        }
    
        .c {
        fill-opacity: .7
        }
      </style>
      <g fill="none">
        <g fill="#E22807">
          <path
            d="M47.059 170.2c6.4.2 11.2 1.8 14.2 4.9 3 3.1 17.3 17.6 43 43.4 25.2-25.6 39.5-40 42.7-43.2 3.1-3.3 7.8-5 14.1-5 12.6 0 18.9 6.4 18.9 19.1v115.1c0 12.8-6.4 19.3-19.2 19.4-12.5 0-18.9-6.5-19.1-19.4v-67.7l-23.6 24.4c-3.1 3.2-7.8 4.7-14.2 4.7-5 .4-10-1.3-13.8-4.7-3.3-3.4-11.2-11.4-23.9-24.2v67.4c0 12.7-6.3 19.1-18.8 19.1-12.6 0-18.9-6.4-18.9-19.1V189.3c0-12.8 6.3-19.1 18.9-19.1h-.3zM216.459 170c12.6 0 19 6.2 19.1 18.5v58.4c.2 25.6 9.8 38.5 28.8 38.5 19.1.1 28.5-12.8 28.3-38.6v-57.7c.2-12.7 6.5-19.1 19.1-19.3 12.6.4 18.9 6.8 18.9 19.5v57.6c0 51.1-22.1 76.6-66.4 76.6-44.4.4-66.7-25.2-66.8-76.6v-57.8c.1-12.6 6.4-18.9 18.8-19l.2-.1zM364.559 170l96 .2c11.8.2 17.7 6.4 17.8 18.6 0 13-6.4 19.6-19.2 19.9h-28.3l.1 95.8c-.1 12.6-6.5 18.9-19 19.1-12.6.1-18.9-6.1-19-18.6l.1-96.3h-28.5c-12.7 0-19-6.4-19-19.3s6.4-19.4 19-19.4zM512.759 170l96 .2c11.7.2 17.7 6.4 17.8 18.6 0 13-6.5 19.6-19.3 19.9h-75.4V285h75.4c12.8 0 19.1 6.5 19.1 19.4 0 12.6-6.2 19-18.7 19.1h-94.9c-12.6 0-18.9-6.2-19-18.6V189.4c.1-12.7 6.4-19.2 19-19.4zm28.3 77.3c0-12.7 6.3-19.2 18.7-19.4h38.1c12.5 0 18.9 6.3 19.2 19.1-.3 12.8-6.7 19.1-19.2 19h-38.1c-12.6 0-18.8-6.3-18.8-18.9l.1.2zM728.959 170.2c12.4.1 24.3 5.3 32.8 14.5 9.1 8.6 14.2 20.6 14.1 33.2.4 11.6-2 23.2-7 33.6-4.7 9.1-11.9 13.8-21.5 14.2l23.3 23.9c3.9 4 5.9 9.3 5.7 14.9-.2 12.7-6.5 19.1-18.9 19.1h-.4c-6.3 0-12.5-3.2-18.6-9.4l-38-47.7c-6.4-6.9-9.6-13.5-9.7-19.8 0-12.9 6.4-19.4 19.2-19.3h13.4c10 .2 15-2.9 14.8-9.2-.2-6.3-5.1-9.5-14.9-9.5h-41.9v95.7c.1 12.8-6.2 19.1-19.1 19-12.8 0-19.1-6.4-18.8-18.9V189.1c0-12.5 6.3-18.8 18.8-18.9h66.7z" />
        </g>
        <path d="M.159 337.7v15.5l1120 .3V338z" class="a" />
        <path
            d="M1098.859 338l-.7-2.5c-3.2-11.4-13.1-19.3-24.7-19.9l-11.1-.5c-2.9-.1-5.7-1.4-7.7-3.5l-5.1-5.2c-4.2-4.1-9.5-6.8-15.3-7.7l-3.4-30.5c-.6-6.6-6.1-11.6-12.7-11.6h-15.8c-3.6-.1-7 1.4-9.5 4l-1.5 1.6-63.8-14.8-12.5 41.2-25.4-12.9h-34.6l-17.7 34.9c-.6.1-1.2.4-1.9.6l-14.1 5.3c-5.7 2.1-10.1 6.8-12 12.6l-2.8 8.7 292.3.2z"
            class="a" />
        <path d="M1015.859 272l3 27.6-16.2 2.2c-4.1.5-8 2-11.4 4.3V284l11.8-12.1 12.8.1z" class="b" />
        <path
              d="M916.359 337.8h-44.6l-3.2-9.8c-1.5-4.8-4.7-8.8-9-11.3l-6.2-3.6 11.1-21.9h21.6l16.7 8.5 13.6 38.1zM1082.859 338h-95.3l8.5-14.9c1.8-3.2 5-5.4 8.6-5.8l24-3.4c3.6-.5 7.3.8 9.9 3.4l5.1 5.2c4.8 4.8 11.2 7.7 17.9 8l11 .5c4.5.2 8.4 2.9 10.3 7z"
              class="c" />
        <path fill="#fff" fill-opacity=".9"
                d="M855.659 337.8h-33l1.2-3.9c.5-1.3 1.5-2.4 2.8-2.9l14.1-5.3c1.3-.5 2.7-.3 3.9.3l7.3 4.2c1 .6 1.7 1.5 2.1 2.6l1.6 5z" />
        <path fill="#649E02"
                  d="M968.259 338l23-31.9.3-43.9.2-207-62.2-54.7h-75.6V8c0 11.8 4.4 23.2 12.4 31.8l-29.5 38 9 7.8c15.1 13.4 37.4 14 53.2 1.5l8.7 6.9-20.4 13.3 10.6 12.3c8.9 10.4 23.3 13.9 35.9 8.8l-9.6 25.5-57.5-39.2c-12.6-9.1-30-6-39 6.7-8.9 12.8-5.9 30.5 6.7 39.6l48.6 36.2 17.5 27.5 27.3 22.7-12.6 41.2 17.6 49.2 35.4.2z" />
        <path fill="#fff" fill-opacity=".8"
                    d="M975.959 327.3l-7.7 10.7-35.4-.2-8.9-25 21.5-70.7-33.3-27.8-17.8-27.8-50.8-37.9c-4-3-5.9-8.2-4.8-13.1 1.1-5 4.9-8.8 9.8-9.8 3.4-.7 6.8 0 9.6 1.9l73.4 50.3 18-48V72l-31.1-32.9h-18.6c-14 0-26.2-9.6-29.7-23.3h53.7l52.6 46.3-.5 265.2z" />
        <path fill="#fff" fill-opacity=".6"
                      d="M934.259 78.2v17.2l-36.6-29-4.7 5.3c-9 10.1-24 11.7-34.9 3.9l20.4-26.3c6.6 3.6 14 5.5 21.4 5.5h12.1l22.3 23.4z" />
        <path d="M920.359 104.1l10.5 8.3c-6.4 4.3-14.9 3.5-20.4-1.8l9.9-6.5z" class="b" />
      </g>
    </svg>
    """
