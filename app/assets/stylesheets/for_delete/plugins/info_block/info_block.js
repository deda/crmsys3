$(document).ready(function(){
	infoBlock.init();
});

infoBlock = {
	init:function(){
		var _my = this;
		this.infoBlock = $('.right-column .info-block');
		$('.withInfo').hover(function(){
			_my.infoBlock.find('#info'+$(this).attr('rel')).addClass('visible');
		}, function(){
			_my.infoBlock.find('#info'+$(this).attr('rel')).removeClass('visible');
		});
	}
}


