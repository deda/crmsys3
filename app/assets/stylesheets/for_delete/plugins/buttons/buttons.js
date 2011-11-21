$(document).ready(function(){
	buttons.init();
});

buttons = {
	init:function(){
		$('ul.buttons li').hover(function(){
			$(this).addClass('hover');
		}, function(){
			$(this).removeClass('hover');
		});
	}
}

