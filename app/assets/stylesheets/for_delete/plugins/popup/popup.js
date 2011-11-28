$(document).ready(function(){
	bubble.init();
});

bubble = {
	init:function(){
		var _my = this;
		this.popup = $('#popup');
		this.dark = $('#darkLayer');
		this.close = this.popup.find('span.close');
		this.close.click(function(){
			_my.popup.removeClass('p-visible');
			_my.dark.removeClass('p-visible');
		});
		this.buttons = $('.popup-button');
		this.buttons.click(function(){
			_my.popup.addClass('p-visible');
			_my.dark.addClass('p-visible');
		});
	}
}

