$( document ).ready(function() {
  
  // mark the current select section of the application in the secondary nav bar
  $('.header-nav-secondary a').click(function(){
  	alert("A Click");
  	this.addClass('currentlyActive');

});