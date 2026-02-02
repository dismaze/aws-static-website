// eleventy.config.js
module.exports = function (eleventyConfig) {
    // Copy images and JS to _site folder automatically
    eleventyConfig.addPassthroughCopy("_src/img");
    eleventyConfig.addPassthroughCopy("_src/js");

    return {
        dir: {
            input: "_src",
            output: "_site"
        }
    };
};