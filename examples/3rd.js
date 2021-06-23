/*
slide html will execute this js file.
Here to load plugins js file and other needed assets,
then set revealConfig,
after this executed, slide html will call
window.addEventListener("load", function(){Reveal.initialize(revealConfig);}); 
*/

//Chalkboard
new_element = document.createElement("link");
new_element.rel = "stylesheet";
new_element.href = "https://use.fontawesome.com/releases/v5.15.3/css/all.css";
document.getElementsByTagName("head")[0].appendChild(new_element);

new_element = document.createElement("link");
new_element.rel = "stylesheet";
new_element.href = "./reveal.js/plugin/chalkboard/style.css";
document.getElementsByTagName("head")[0].appendChild(new_element);

new_element = document.createElement("script");
new_element.type = "text/javascript";
new_element.src = "./reveal.js/plugin/chalkboard/plugin.js";
new_element.onload = function () {
  revealConfig.plugins.push(RevealChalkboard);
  revealConfig.chalkboard={ // font-awesome.min.css must be available
    src: "chalkboard/chalkboard.json",
    storage: "chalkboard-demo",
    toggleChalkboardButton: { left: "80px" },
    toggleNotesButton: { left: "130px" },
    colorButtons: 5
  }

};
document.getElementsByTagName("head")[0].appendChild(new_element);

//menu
new_element = document.createElement("script");
new_element.type = "text/javascript";
new_element.src = "./reveal.js/plugin/menu/menu.js";
document.getElementsByTagName("head")[0].appendChild(new_element);
new_element.onload = function () {
  revealConfig.plugins.push(RevealMenu);

};