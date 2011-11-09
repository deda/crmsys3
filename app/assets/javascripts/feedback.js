//------------------------------------------------------------------------------
var feedback = {

    timer_id: null,

    toggle: function (me) {
        $(me).parents('.feedback').toggleClass('hidded').removeClass('messaged');
        if (feedback.timer_id) {
            clearTimeout(feedback.timer_id);
        }
    },

    submit: function (me) {
        $(me).parents('form').submit();
    },

    show_message: function () {
        $('.feedback').addClass('messaged').find('textarea, input[type=file]').val('');
        feedback.timer_id = setTimeout(feedback.hide_message, 3000);
    },

    hide_message: function () {
        $('.feedback').removeClass('messaged').addClass('hidded');
        if (feedback.timer_id) {
            clearTimeout(feedback.timer_id);
        }
    }
}
