// ==UserScript==
// @name          SCPD
// @namespace     http://quadpoint.org/
// @description   Various SCPD hacks
// @include       https://myvideosu.stanford.edu/*
// ==/UserScript==

/**
 * Extracts .wmv URL from 'text'.
 */
function extractVideoURL(text) {
  var pattern = /(http:\/\/.+?\.wmv)/i;
  var matches = pattern.exec(text);
  if (matches.length > 1) {
    return matches[1];
  }

  return null;
}


/**
 * Fetch video URL for the 'anchor' DOM element and update it to provide a
 * direct link to the video.
 */
function rewriteLink(anchor) {
  /* Extract href. "javascript:void(...('https://..." */
  var href = anchor.getAttribute('href');

  var pattern = /(https:\/\/.+?wmp=true)/i;
  var m = pattern.exec(href);
  if (m == null) {
    return;
  }
  var url = m[0];

  /* Set link to updating while we do the XHR. */
  anchor.setAttribute('href', '#');
  anchor.innerHTML = 'Fetching...';

  var xhr = new XMLHttpRequest();
  xhr.overrideMimeType('text/xml');
  xhr.onreadystatechange = function () {
    if (xhr.readyState == 4 && xhr.status == 200) {
      var wmv = extractVideoURL(xhr.responseText);
      if (wmv != null) {
        /* Update the URL for the link. */
        anchor.setAttribute('href', wmv);
        /* Change the text. */
        anchor.innerHTML = 'Video link';
      }
    }
  }

  xhr.open('GET', url, true);
  xhr.send();
}


/* Rewrite all WMP links. */
var links = document.getElementsByTagName('a');
var delay = 0;
for (idx in links) {
  /* Only interested in WMP links. */
  if (links[idx].innerHTML != 'WMP')
    continue;

  function closure(index) {
    return function () {
      rewriteLink(links[index]);
    }
  }

  /* Stagger the link rewrites. */
  window.setTimeout(closure(idx), delay);
  delay += 500;  /* ms */
}