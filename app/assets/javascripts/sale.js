/* -----------------------------------------------------------------------------
 * Sale functions
 * ---------------------------------------------------------------------------*/

var sale = {

    me:                     null,
    form:                   null,
    num_of_cols:            0,
    item_price:             0,
    item_quantity:          null,
    item_price_discount:    null,
    item_price_total:       null,
    item_discount_select:   null,
    item_discount_value:    null,
    item_error:             false,
    discount_cur:           0,
    price_total:            0,
    decimal_pat:            /^[0-9]{1,6}(\.|\,)?[0-9]{0,3}$/,

    init: function (me) {
        if (sale.me == me) {
            return;
        }
        sale.me = me;
        sale.form = $(me);
        sale.discount_cur = sale._get_float(sale.form.find('#sale_discount_cur').text());
        sale.price_total = sale._get_float(sale.form.find('#sale_price_total').text());
        sale.num_of_cols = sale.form.find('th').size();
        var s;
        if ((sale.item_price = sale._get_float(sale.form.find('#sale_new_item_price').text()||'0')) > 0) {
            s = '#sale_new_item_';
        } else if ((sale.item_price = sale._get_float(sale.form.find('#sale_chg_item_price').text()||'0')) > 0) {
            s = '#sale_chg_item_';
        } else {
            s = null;
        }
        if (s) {
            sale.item_quantity = sale.form.find(s + 'quantity');
            sale.item_price_discount = sale.form.find(s + 'price_discount');
            sale.item_price_total = sale.form.find(s + 'price_total');
            sale.item_discount_select = sale.form.find(s + 'discount_id').parent();
            sale.item_discount_value = sale.form.find(s + 'discount_value');
            sale.item_quantity.keydown(sale.on_change_quantity).blur(sale.on_change_quantity);
            sale.item_price_discount.keydown(sale.on_change_price_discount).blur(sale.on_change_price_discount);
            sale.item_price_total.keydown(sale.on_change_price_total).blur(sale.on_change_price_total);
            sale.item_discount_value.keydown(sale.on_change_discount).blur(sale.on_change_discount);
            if (s == '#sale_chg_item_') {
                var item = sale._get_item_values();
                sale.discount_cur -= (sale.item_price * item.q - item.pt);
                sale.price_total -= item.pt;
            }
            sale._set_item_values(sale._get_item_values());
        }
    },

    new_item: function (v, sa, si) {
        if (v) {
            sa = 'new_item'
            si = v[0];
        }
        $.ajax({
            url      : sale.form.attr('action'),
            type     : sale.form.attr('method'),
            dataType : 'script',
            data     : getFormValues(sale.form) + 'sub_action=' + sa + '&sub_action_id=' + si});
        sale.form.find('table.items tr:last').before('<tr><td class="item_opers"></td><td></td><td>'+v[1]+'</td><td>'+v[2]+'</td><td colspan="'+(sale.num_of_cols-3)+'"><img src="/images/ajax.gif"/></td></tr>');
        sale._numerate_first_col();
    },

    on_change_price_total: function (e) {
        if (sale._event_ok(e,sale.item_price_total)) {
            var item = sale._get_item_values();
            if (item.pt && item.pt > 0) {
                if (item.q && item.q > 0) {
                    item.dv = (100.0 - item.pt / item.q / sale.item_price * 100.0).toFixed(2);
                    if (item.dv >=0 && item.dv < 100) {
                        item.pd = (sale.item_price * (1.0 - item.dv / 100.0)).toFixed(2);
                        item.pt = (item.pd * item.q).toFixed(2);
                        sale._set_item_values(item);
                        sale.item_discount_select.hide();
                        sale.item_discount_value.parent().show();
                    } else {
                        sale._set_error(sale.item_price_total);
                    }
                } else {
                    sale._set_error(sale.item_quantity);
                }
            } else {
                sale._set_error(sale.item_price_total);
            }
            e.preventDefault();
            e.stopPropagation();
        }
    },

    on_change_discount: function (e) {
        if (sale._event_ok(e,sale.item_discount_value)) {
            var item = sale._get_item_values();
            if (item.dv && item.dv >= 0 && item.dv < 100) {
                if (item.q && item.q > 0) {
                    item.pd = (sale.item_price * (1.0 - item.dv / 100.0)).toFixed(2);
                    item.dv = (100.0 - item.pd / sale.item_price * 100.0).toFixed(2);
                    item.pd = (sale.item_price * (1.0 - item.dv / 100.0)).toFixed(2);
                    item.pt = (item.pd * item.q).toFixed(2);
                    sale._set_item_values(item);
                } else {
                    sale._set_error(sale.item_quantity);
                }
            } else {
                sale._set_error(sale.item_discount_value);
            }
            e.preventDefault();
            e.stopPropagation();
        }
    },

    on_change_quantity: function (e) {
        if (sale._event_ok(e,sale.item_quantity)) {
            var item = sale._get_item_values();
            if (item.q && item.q > 0) {
                if (item.pd && item.pd > 0) {
                    item.pt = (item.pd * item.q).toFixed(2);
                    sale._set_item_values(item);
                } else {
                    sale._set_error(sale.item_price_discount);
                }
            } else {
                sale._set_error(sale.item_quantity);
            }
            e.preventDefault();
            e.stopPropagation();
        }
    },

    on_change_price_discount: function (e) {
        if (sale._event_ok(e,sale.item_price_discount)) {
            var item = sale._get_item_values();
            if (item.pd && item.pd > 0) {
                if (item.q && item.q > 0) {
                    item.dv = (100.0 - item.pd / sale.item_price * 100.0).toFixed(2);
                    if (item.dv >=0 && item.dv < 100) {
                        item.pd = (sale.item_price * (1.0 - item.dv / 100.0)).toFixed(2);
                        item.pt = (item.pd * item.q).toFixed(2);
                        sale._set_item_values(item);
                        sale.item_discount_select.hide();
                        sale.item_discount_value.parent().show();
                    } else {
                        sale._set_error(sale.item_price_discount);
                    }
                } else {
                    sale._set_error(sale.item_quantity);
                }
            } else {
                sale._set_error(sale.item_price_discount);
            }
            e.preventDefault();
            e.stopPropagation();
        }
    },

/* private */

    _numerate_first_col: function () {
        sale.form.find('table.items td:nth-child(2)').each(function(n){
            this.innerHTML = n+1;
        });
    },

    _get_float: function (str) {
        if ( ! str.match(/^[0-9]{1,6}(\.|\,)?[0-9]*$/) )
            return false;
        str.replace(/\,/,'.');
        return parseFloat(str).toFixed(2);
    },

    _event_ok: function (e,i) {
        return (!sale.item_error || i.hasClass('error')) && (e.type == 'blur' || e.keyCode == 13);
    },

    _set_error: function (i) {
        i.addClass('error');
        sale.item_error = true;
    },

    _res_errors: function () {
        sale.form.find('input').removeClass('error');
        sale.item_error = false;
    },

    _get_item_values: function () {
        return {
            dv : sale._get_float(sale.item_discount_value.val()),
            pd : sale._get_float(sale.item_price_discount.val()),
            q  : sale._get_float(sale.item_quantity.val()),
            pt : sale._get_float(sale.item_price_total.val())}
    },

    _set_item_values: function (item) {
        sale.item_discount_value.val(item.dv);
        sale.item_price_discount.val(item.pd);
        sale.item_quantity.val(item.q);
        sale.item_price_total.val(item.pt);
        dc = (sale.item_price * item.q - item.pt + 1*sale.discount_cur).toFixed(2);
        pt = (1*item.pt + 1*sale.price_total).toFixed(2);
        dp = (dc / (1*pt + 1*dc) * 100.0).toFixed(2);
        sale.form.find('#sale_discount_cur').text(dc);
        sale.form.find('#sale_discount_per').text(dp);
        sale.form.find('#sale_price_total').text(pt);
        sale._res_errors();
    }
}
