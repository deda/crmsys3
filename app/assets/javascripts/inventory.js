/* -----------------------------------------------------------------------------
 * Inventory functions
 * ---------------------------------------------------------------------------*/

var inventory = {

    add:    function () {this._send('sub_action=add')},

    apply:  function () {this._send('sub_action=apl')},

    cancel: function () {this._send('sub_action=uhg')},

    change: function (i) {this._send('sub_action=chg&sub_action_id='+i)},

    destroy:function (i) {
        if (confirm(locmes.confirm_delete))
            this._send('sub_action=del&sub_action_id='+i);
    },

    _send: function (sub_action) {
        this.form = $('.central_container').find('form:first');
        $.ajax({
            url      : this.form.attr('action'),
            type     : this.form.attr('method'),
            dataType : 'script',
            data     : getFormValues(this.form) + sub_action
        });
    }
}
