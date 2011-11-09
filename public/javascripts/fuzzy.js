/* -----------------------------------------------------------------------------
 * Fuzzy search functions
 * ---------------------------------------------------------------------------*/

var fuzzy = {

    query       : null,
    result      : null,
    result_id   : null,
    last_value  : null,
    models      : null,
    fields      : null,
    id_timer    : null,
    on_select   : null,
    in_result   : null,
    mfm         : false,

    init: function (me, models, fields, on_select, mfm) {
        fuzzy.hide_all_results();
        fuzzy._init(me, models, fields, on_select, mfm);
    },

    _init: function (me, models, fields, on_select, mfm) {
        $('body').bind('click',fuzzy.hide_all_results);
        fuzzy.query = $(me);
        fuzzy.result = fuzzy.query.nextAll('.fuzzy_result:first');
        fuzzy.result_id = fuzzy.query.nextAll('.fuzzy_id:first');
        fuzzy.result.width(fuzzy.query.width());
        fuzzy.query.
            unbind().
            bind('keydown',fuzzy.move_and_select).
            bind('keyup',fuzzy.search).
            bind('blur',fuzzy.hide_on_blur).
            bind('click',fuzzy.toggle);
        fuzzy.models = models;
        fuzzy.fields = fields;
        fuzzy.on_select = on_select;
        fuzzy.result.
            unbind('scroll').
            bind('mousedown',function(){fuzzy.in_result=true});
        fuzzy.mfm = mfm;
        fuzzy.query_name = fuzzy.query.attr('name');
    },

    browse: function (me, text, models, fields, on_select, mfm) {
        fuzzy._init($(me).prev(), text, models, fields, on_select, mfm);
        var fuzzy_result_is_visible = fuzzy.result.is(':visible');
        fuzzy.hide_all_results();
        if (!fuzzy_result_is_visible) {
            if (fuzzy.cache.is_empty()) {
                fuzzy.cache.need_load(true);
                fuzzy.send_request_for();
            } else {
                setTimeout(function(){
                    var s = fuzzy.cache.content();
                    fuzzy.result.html(s);
                    fuzzy.show_result(s);
                }, 1);

            }
        }
    },

    stop: function () {
        fuzzy.result.hide();
    },

    move_and_select: function (e) {
        var a = fuzzy.result.children('div.active');
        if (e.keyCode == 38 || e.keyCode == 40) {
           if (a.size() != 0)
               a.removeClass('active');
            if (fuzzy.result.is(':hidden')) {
                if (fuzzy.result.children('div').size() != 0)
                    fuzzy.result.show();
            } else {
                if (e.keyCode == 38) {
                    a = a.prev();
                    if (a.size() == 0)
                        a = fuzzy.result.children('div:last');
                } else {
                    a = a.next();
                    if (a.size() == 0)
                        a = fuzzy.result.children('div:first');
                }
                a.addClass('active');
            }
        } else if (e.keyCode == 27) {
            fuzzy.result.hide();
        } else if (e.keyCode == 13) {
            if (a.size() != 0) {
                e.preventDefault();
                e.stopPropagation();
                a.mousedown();
            }
        }
        fuzzy.in_result = false;
    },

    search: function (e) {
        if (e.keyCode && e.keyCode != 13 && e.keyCode != 38 && e.keyCode != 40 && e.keyCode != 27) {
            if (fuzzy.last_value != fuzzy.query.val()) {
                if (fuzzy.result_id) {
                    fuzzy.result_id.val('');
                }
                if (fuzzy.id_timer)
                    clearTimeout(fuzzy.id_timer);
                fuzzy.id_timer = setTimeout(fuzzy.send_request, 300);
                fuzzy.in_result = false;
            }
        }
    },

    send_request: function () {
        if (fuzzy.query.val().length) {
            fuzzy.send_request_for(fuzzy.query.val());
        } else {
            fuzzy.result.hide();
        }
        fuzzy.last_value = fuzzy.query.val();
    },

    send_request_for: function (v) {
        fuzzy.result.load(
            '/fuzzy/search',
            {models:fuzzy.models, fields:fuzzy.fields, value:(v || '').toLowerCase(), mfm:fuzzy.mfm},
            fuzzy.show_result);
    },

    show_result: function (a) {
        if (a.length > 0) {
            if (fuzzy.cache.need_load()) {
                fuzzy.cache.load(a);
            }
            if (fuzzy.query.val() != '') {
                var s = RegExp('(('+fuzzy.query.val()+')+)', 'gi');
                var r = '<b>$1</b>';
                fuzzy.result.html(fuzzy.result.html().replace(s,r));
            }
            fuzzy.result_after_query();
            fuzzy.result.children('div').bind('mousedown',fuzzy.select_result);
            fuzzy.result.show();
        } else {
            fuzzy.result.hide();
        }
    },

    select_result: function () {
        var v, i, c, f, s;
        v = this.innerHTML.replace(/<\/?[^<>]+\/?>/gim,'').split('&nbsp;');
        s = '';
        for (i = 0; i < v.length; i++) {
            v[i] = v[i].trim();
            if (i > 0) {
                s += v[i];
                if (i < v.length - 2)
                    s += ' ';
            }
        }
        fuzzy.query.val(s).keyup();
        fuzzy.last_value = fuzzy.query.val();
        if (fuzzy.result_id) {
            fuzzy.result_id.val(v[0]);
        }
        fuzzy.stop();
        if (fuzzy.on_select) {
            try {
                c = fuzzy.on_select.split('.');
                f = window[c[0]];
                for (i = 1; i < c.length; i++)
                    f = f[c[i]];
                f(v);
                fuzzy.query.val('');
            }
            catch (e) {
                alert(e);
            }
        }
    },

    result_after_query: function () {
        fuzzy.result.
            css('top',fuzzy.query.offset().top + fuzzy.query.height() + 1).
            css('left',fuzzy.query.offset().left);
    },
    
    toggle: function () {
        fuzzy.in_result = false;
        if (fuzzy.result.is(':visible')) {
            fuzzy.stop();
        } else {
            fuzzy.send_request();
        }
    },

    hide_all_results: function () {
        $('.fuzzy_result:visible').hide();
    },

    hide_on_blur: function () {
        if (! fuzzy.in_result) {
            fuzzy.stop();
        }
        fuzzy.in_result = false;
    },

    cache: {

        is_empty: function () {
            return fuzzy.cache.instance().hasClass('empty');
        },

        need_load: function (f) {
            var i = fuzzy.cache.instance();
            var c = 'need_load';
            if (f) {
                i.addClass(c);
            }
            return i.hasClass(c);
        },

        load: function (s) {
            fuzzy.cache.instance().html(s).removeClass('empty need_load');
        },

        content: function () {
            return fuzzy.cache.instance().html();
        },

        instance: function () {
            var p = fuzzy.query.parents('.fuzzy_wrapper');
            var c = p.find('.fuzzy_cache');
            if (c.size() == 0) {
                p.append('<div class="fuzzy_cache" style="display:none"></div>');
                c = p.find('.fuzzy_cache');
                c.addClass('empty');
            }
            return c;
        }
    }
}
