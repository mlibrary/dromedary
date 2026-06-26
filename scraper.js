(function() {
    // 1. Set the environment tracking attributes on the root HTML node
    document.documentElement.setAttribute('data-source-url', window.location.href);

    const targetedProps = [
        'width', 'height', 'color', 'background-color',
        'display', 'position', 'margin', 'padding',
        'font-size', 'font-family', 'flex-direction',
        'grid-template-columns', 'opacity', 'visibility',
        'z-index', 'box-sizing', 'overflow', 'text-align'
    ];

    // Compute and apply styles for the HTML element itself
    const htmlComputed = window.getComputedStyle(document.documentElement);
    let htmlCompiledString = '';
    for (let prop of targetedProps) {
        const value = htmlComputed.getPropertyValue(prop);
        if (value && value !== 'none' && value !== 'normal' && value !== 'rgba(0, 0, 0, 0)') {
            htmlCompiledString += prop + ': ' + value + '; ';
        }
    }
    if (htmlCompiledString) {
        document.documentElement.setAttribute('data-computed-css', htmlCompiledString.trim());
    }

    // 2. Loop strictly through body tags, excluding non-visual elements entirely
    const bodyElements = document.querySelectorAll('body, body *');
    const excludedTags = ['SCRIPT', 'STYLE', 'META', 'LINK', 'TEMPLATE', 'NOSCRIPT', 'HEAD', 'TITLE'];

    for (let el of bodyElements) {
        if (excludedTags.includes(el.tagName)) continue;

        const computed = window.getComputedStyle(el);
        if (computed.getPropertyValue('display') === 'none') continue;

        let compiledString = '';
        for (let prop of targetedProps) {
            const value = computed.getPropertyValue(prop);

            if (!value) continue;
            if (value === 'none' || value === 'normal' || value === 'rgba(0, 0, 0, 0)') continue;
            if (prop === 'position' && value === 'static') continue;
            if (prop === 'display' && value === 'inline') continue;
            if (prop === 'z-index' && value === 'auto') continue;
            if (prop === 'visibility' && value === 'visible') continue;
            if ((prop === 'margin' || prop === 'padding') && (value === '0px' || value === '0px 0px')) continue;
            if (prop === 'overflow' && value === 'visible') continue;
            if (prop === 'box-sizing' && value === 'content-box') continue;

            compiledString += prop + ': ' + value + '; ';
        }
        if (compiledString) {
            el.setAttribute('data-computed-css', compiledString.trim());
        }
    }
    return document.documentElement.outerHTML;
})()
