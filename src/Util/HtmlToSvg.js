// Adapted from https://github.com/cburgmer/rasterizeHTML.js/blob/master/src/document2svg.js

"use strict";

var svgAttributes = function (size, zoom) {
  var zoomFactor = zoom || 1;

  var attributes = {
    width: size.width,
    height: size.height,
    'font-size': size.rootFontSize
  };

  if (zoomFactor !== 1) {
    attributes.style = 'transform:scale(' + zoomFactor + '); transform-origin: 0 0;';
  }

  return attributes;
};

var foreignObjectAttributes = function (size) {
  var closestScaledWith, closestScaledHeight,
  offsetX, offsetY;

  closestScaledWith = Math.round(size.viewportWidth);
  closestScaledHeight = Math.round(size.viewportHeight);

  offsetX = -size.left;
  offsetY = -size.top;

  var attributes = {
    'x': offsetX,
    'y': offsetY,
    'width': closestScaledWith,
    'height': closestScaledHeight
  };

  return attributes;
};

var workAroundCollapsingMarginsAcrossSVGElementInWebKitLike = function (attributes) {
  var style = attributes.style || '';
  attributes.style = style + 'float: left;';
};

var workAroundSafariSometimesNotShowingExternalResources = function (attributes) {
  /* Let's hope that works some magic. The spec says SVGLoad only fires
  * now when all externals are available.
  * http://www.w3.org/TR/SVG/struct.html#ExternalResourcesRequired */
  attributes.externalResourcesRequired = true;
};

var workAroundChromeShowingScrollbarsUnderLinuxIfHtmlIsOverflowScroll = function () {
  return '<style scoped="">html::-webkit-scrollbar { display: none; }</style>';
};

var serializeAttributes = function (attributes) {
  var keys = Object.keys(attributes);
  if (!keys.length) {
    return '';
  }

  return ' ' + keys.map(function (key) {
    return key + '="' + attributes[key] + '"';
  }).join(' ');
};

exports.convertHtmlToSvg = function (xhtml, size, zoomFactor) {
  // `size` should have keys 'width', 'height', 'viewportWidth',
  // 'viewportHeight', 'left', 'top', and 'rootFontSize'

  // browser.validateXHTML(xhtml);

  var foreignObjectAttrs = foreignObjectAttributes(size);
  workAroundCollapsingMarginsAcrossSVGElementInWebKitLike(foreignObjectAttrs);
  workAroundSafariSometimesNotShowingExternalResources(foreignObjectAttrs);

  return (
    '<svg xmlns="http://www.w3.org/2000/svg"' +
    serializeAttributes(svgAttributes(size, zoomFactor)) +
    '>' +
    workAroundChromeShowingScrollbarsUnderLinuxIfHtmlIsOverflowScroll() +
    '<foreignObject' + serializeAttributes(foreignObjectAttrs) + '>' +
    xhtml +
    '</foreignObject>' +
    '</svg>'
  );
};

exports.convertHtmlToSvgSimple = function (xhtml, width, height) {
  return exports.convertHtmlToSvg(xhtml, {
    width: width, height: height,
    viewportWidth: width, viewportHeight: height,
    left: 0, top: 0, rootFontSize: 100
  });
};
