// Place your application-specific JavaScript functions and classes here
// This file is automatically included by javascript_include_tag :defaults
Function.prototype.bind = function(object){
    var __method = this;
    return function() {
        __method.apply(object, arguments);
    };
};

//------------------------------------------------------------------------------
function trim(s){return s.replace(/^\s*([\S\s]*?)\s*$/, '$1')}
function getAbsolutePosition(e){var r={x:0,y:0};while(e){r.x+=(e.offsetLeft+e.clientLeft);r.y+=(e.offsetTop+e.clientTop);e=e.offsetParent;}return r}
function getAbsolutePositionById(i){return getAbsolutePosition(document.getElementById(i))}
function getFormValues(f){var s='';f.find(':not(:checkbox,:radio),:checked').each(function(){s+=this.name+'='+$(this).val()+'&'});return s}

//------------------------------------------------------------------------------
var mass = {

    confirmed: false,

    destroy: function (controller_name, confirmed) {
        if (confirmed) {
            mass.confirmed = true;
            mass._do(controller_name, null, 'destroy');
        } else {
            mass._do(controller_name, locmes.confirm_delete, 'destroy');
        }
    },

    accept: function (controller_name) {
        mass._do(controller_name, locmes.confirm_accept, 'accept');
    },

    state: function (me, controller_name) {
        $(me).hide().next().show().
            mouseover(function(){$(this).show().prev().hide()}).
            mouseout(function(){$(this).hide().prev().show()}).
            find('a').click(function(){
                $(this).parent().hide().prev().show();
                mass._do(controller_name, null, 'state', this.className);
            });
    },

    task: function (controller_name) {
        var url = '/tasks/mass_new?cn=' + controller_name;
        $(":checkbox.mass_oper:checked").each(function(k,v){
            url += '&ids[]=' + v.value;
        });
        window.location.href = url;
    },

    select: function (me, cn) {
        switch ($(me).val()) {
            case '0':mass._sel_non(cn);break;
            case '1':mass._sel_all(cn);break;
            case '2':mass._sel_inv(cn);break;
        }
        $(me).val('');
        left_menu.correct();
    },

    _sel_all: function (cn) {
        $('[name='+cn+'_ids[]].mass_oper:not(checked):visible:enabled').attr('checked', 'checked');
    },

    _sel_non: function (cn) {
        $('[name='+cn+'_ids[]].mass_oper:checked:visible:enabled').removeAttr('checked');
    },

    _sel_inv: function (cn) {
        $('[name='+cn+'_ids[]].mass_oper:visible:enabled').each(function(k,v){
            v = $(v);
            if (v.attr('checked'))
                v.removeAttr('checked');
            else
                v.attr('checked', 'checked');
        });
    },

    _do: function (controller_name, msg, operation, oper_id) {
        var sel = ":checkbox.mass_oper:checked";
        if (mass.confirmed) {
            mass.confirmed = false;
            sel += ",input.mass_oper[name^=action_for_],select.mass_oper[name^=new_id_for_]";
        }
        var data = $(sel).serializeArray();
        if (data.length && (msg==null || confirm(msg)) ) {
            if (oper_id) {
                data.push({name:'oper_id',value:oper_id});
            }
            $.ajax({
                type:"POST",
                url:"/" + controller_name + "/mass_" + operation,
                async:false,
                data:data,
                dataType:"script"});
        }
    }
}



//------------------------------------------------------------------------------
var hideble = {

    toggle: function (me) {
        $(me).toggleClass('hided');
        $(me).parents('.hideble:first').children('.content').toggleClass('hidden');
    },

    toggle_all: function (me) {
        var i = $('div.hideble a.item_hid_link');
        if ($(me).hasClass('hided')) {
            i.removeClass('hided');
            i.parents('.hideble').children('.content').removeClass('hidden');
        } else {
            i.addClass('hided');
            i.parents('.hideble').children('.content').addClass('hidden');
        }
    },

    show: function (me) {
        var hid_link = $(me).show().parents('.hideble:first').find('.item_hid_link:first');
        if (hid_link.hasClass('hided')) {
            hideble.toggle(hid_link);
        }
    },

    count: function (me, x) {
        var s = $(me).parents('.hideble:first:visible').children('.title').find('span.count');
        var d = s.text().match(/\((\d)\)/);
        if (d) {
            var c = parseInt(d[1])+1*x;
            if (c < 0) {
                c = 0;
            }
            s.text('('+c+')');
        }
    }
}



//------------------------------------------------------------------------------
var addeble = {

    init: function () {
        $('.addeble .content input').live('keyup',addeble.chg);
        $('.addeble a.item_del_link').live('click',addeble.del);
        $('.addeble a.item_add_link').live('click',addeble.add);
    },

    chg: function () {
        addeble._toggle_add_link(addeble._my_table(this));
    },

    add: function () {
        var my_line = addeble._my_line(this);
        var new_line = my_line.prev().clone(true).insertBefore(my_line);
        my_line.hide();
        new_line.addClass('new_line').show();
        addeble._reset_inputs(new_line);
        new_line.find('.label').empty();
        return false;
    },

    del: function () {
        var my_line = addeble._my_line(this);
        var my_table = addeble._my_table(this);
        var my_line_is_top = my_line.prevAll().find('input:visible, textarea:visible').size() == 0;
        var my_line_is_bottom = my_line.nextAll().find('input:visible, textarea:visible').size() == 0;
        var my_line_is_old = !my_line.hasClass('new_line');
        if (my_line_is_top) {
            if (my_line_is_bottom) {
                if (my_line_is_old) {
                    addeble._remove(my_line.clone(true).insertAfter(my_line));
                }
                addeble._reset_inputs(my_line);
            } else {
                my_line.next().find('.label').text(my_line.find('.label').text());
                addeble._remove(my_line);
            }
        } else {
            addeble._remove(my_line);
        }
        addeble._toggle_add_link(my_table);
        return false;
    },

    _my_line: function (me) {
        return $(me).parents('.item_line:first');
    },

    _my_table: function (me) {
        return $(me).parents('.addeble:first');
    },

    _toggle_add_link: function (my_table) {
        var empty_present = false;
        var add_link = my_table.find('tr:last-child');
        my_table.find('td.content:visible').each(function(k,t) {
            var all_empty = true;
            $(t).find('input:visible, textarea:visible').each(function(k,i) {
                if ($(i).val() != '') {
                    all_empty = false;
                    return false;
                }
            })
            if (all_empty) {
                empty_present = true;
                return false;
            }
        })
        if (empty_present) {
            add_link.hide();
        } else {
            if (add_link.hasClass('auto_add')) {
                add_link.find('a.item_add_link').click();
            }else {
                add_link.show();
            }
        }
    },

    _reset_inputs: function (line) {
        line.find('input, textarea').val('');
        line.find('select :only-child').removeAttr('selected');
        line.find('select :first-child').attr('selected','1');
        line.find('p.error, p.fuzzy_error').remove();
        line.find('.error').removeClass('error');
    },

    _remove: function (line) {
        if (line.hasClass('new_line')) {
            line.remove();
        } else {
            line.find('input:visible, textarea').val('');
            line.hide();
        }
    }
}
$(addeble.init);



//------------------------------------------------------------------------------
var ajax_progress = {

    visible: false,

    init: function () {
        $('*').ajaxStart(ajax_progress.show);
        $('*').ajaxComplete(ajax_progress.hide);
    },

    hide: function () {
        if (ajax_progress.visible) {
            ajax_progress.visible = false;
            ajax_progress.sheet().fadeOut(200);
            left_menu.correct();
            hint.init();
        }
    },

    show: function () {
        if (!ajax_progress.visible) {
            ajax_progress.visible = true;
            ajax_progress.sheet().fadeIn(200);
        }
    },

    sheet: function () {
        return $('#ajax_process');
    }
}
$(ajax_progress.init);



//------------------------------------------------------------------------------
var comment = {

    edit_line: null,

    add: function (me) {
        var my_line = comment._my_line(me);
        if (comment.cancel(me)) {
            my_line.content.find('>a').hide();
            my_line.content.find('.title, .dati, .attachmends').show();
            my_line.opers.find('.item_apl_link, .item_uad_link').show();
            my_line.icon.show();
            comment._create_textarea(my_line, comment.create);
            attachmends.to_editable(my_line.attachmends);
            comment.edit_line = me;
        }
    },

    edit: function (me) {
        var my_line = comment._my_line(me);
        if (comment.cancel(me)) {
            my_line.opers.find('.item_del_link, .item_chg_link').hide();
            my_line.content.find('>.text').hide();
            my_line.opers.find('.item_apl_link, .item_uch_link').show();
            comment._create_textarea(my_line, comment.update, my_line.old_text);
            attachmends.to_editable(my_line.attachmends);
            comment.edit_line = me;
        }
    },

    create: function (me) {
        comment._send(me, comment._my_line(me).new_text);
    },

    update: function (me) {
        if (attachmends.sending()) return;
        var my_line = comment._my_line(me);
        if (my_line.new_text == my_line.old_text) {
            comment.cancel(me);
        } else {
            comment._send(me, my_line.new_text);
        }
    },

    del: function (me) {
        if (confirm(locmes.confirm_delete)) {
            comment._send(me, null);
        }
    },

    cancel: function (me) {
        var ret = true;
        var edit_line = null;
        if (!comment.edit_line) {
            var my_line = comment._my_line(me);
            if (my_line.find('.error').size() > 0) {
                edit_line = my_line;
            }
        } else {
            edit_line = comment._my_line(comment.edit_line);
        }
        if (edit_line) {
            if (edit_line.new_text == edit_line.old_text || confirm(locmes.confirm_cancel_edit)) {
                var my_table = $(me).parents('.comments_table:first');
                my_table.opers = my_table.find('> tbody > tr > .item_opers');
                my_table.content = my_table.find('> tbody > tr > .content');
                my_table.opers.find('.item_apl_link, .item_uch_link, .item_uad_link').hide();
                my_table.opers.find('.item_del_link, .item_chg_link').show();
                my_table.content.find('textarea, p.error').remove();
                my_table.find('tr.last').find('>.icon>img, >.content>*').hide();
                my_table.content.find('>.text').show();
                attachmends.to_vieweble(edit_line.attachmends);
                comment.edit_line = null;
            } else {
                ret = false;
            }
        }
        return ret;
    },

    _my_line: function (me) {
        var t;
        var my_line = $(me).parents('.item_line:first');
        my_line.opers = my_line.find('>.item_opers');
        my_line.icon = my_line.find('>.icon>img');
        my_line.content = my_line.find('>.content');
        my_line.old_text = (t = my_line.content.find('>.text').html()) ? t.replace(new RegExp("<br>",'g'), "\n") : '';
        my_line.new_text = (t = my_line.content.find('>textarea').val()) ? t : '';
        my_line.attachmends = my_line.content.find('.attachmends_list');
        return my_line;
    },

    _send: function (me, text) {
        if (attachmends.sending()) return;
        var my_id;
        var owner = $(me).parents('.comments_table:first').attr('id').split('_', 2);
        try {
            my_id = comment._my_line(me).attr('id').match(/.+_(\d+)/)[1];
        } catch (e) {
            my_id = null;
        }
        $.ajax({
            url      : '/comments/' + (my_id || ''),
            type     : text === null ? 'delete' : (my_id ? 'put' : 'post'),
            dataType : 'script',
            data     : {
                text       : text,
                owner_type : owner[0],
                owner_id   : owner[1]}
        });
        comment.edit_line = null;
    },

    _create_textarea: function (my_line, func, content) {
        $('<textarea rows="5">'+(content||'')+'</textarea>').insertAfter(my_line.content.find('.text'));
        my_line.find('textarea').focus().keydown(function(e){
            if (e.keyCode == 13 && (e.ctrlKey || e.altKey || e.shiftKey)) {
                ajax_progress.link = $(this);
                func(this);
            } else if (e.keyCode == 27) {
                comment.cancel(this);
            }
        });
    }
}



//------------------------------------------------------------------------------
var attachmends = {

    uid         : null,
    func_after  : null,
    args_after  : null,
    self_after  : null,

    init: function () {
        $('.attachmends_list .item_del_link').live('click', attachmends.del);
        $('.attachmends_list .item_add_link input').live('change', attachmends.sel);
        attachmends.uid = attachmends.uid || 0;
    },

    del: function () {
        if (confirm(locmes.confirm_delete)) {
            var my_line = attachmends._my_line(this);
            var id = my_line.id.match(/.+_(\d+)/)[1];
            if (my_line.id.match(/_sending/)) {
                $('form[target=attachmend_'+id+']').remove();
                my_line.remove();
            } else {
                $.ajax({
                    url      : '/attachmends/' + id,
                    type     : 'delete',
                    dataType : 'script'});
            }
        }
    },

    sel: function () {
        var my_uid = attachmends._get_uid();
        var my_owner = attachmends._my_owner(this);
        var my_line = attachmends._my_line(this);
        var my_input = $(this);
        var my_form = attachmends._build_form(my_uid, my_owner);
        var parent_form = my_line.parents('form');
        my_line.clone().insertAfter(my_line).find('input').val('');
        my_form.append(my_input);
        my_line.attr('id', my_uid+'_sending');
        my_line.icon.addClass('item_del_link');
        my_line.link.text(my_input.val().replace(/.*(\/|\\)/, ""));
        my_line.prog.addClass('active');
        if (parent_form.size() != 0) {
            parent_form.submit(function(){
                if (attachmends.sending(this)) return false;
                $(this).unbind('submit').submit();
                return false;
            });
        }
        my_form.submit();
    },

    to_editable: function (my_table) {
        my_table.find('.attachmend_line[id*=show]').each(function(){
            this.id = this.id.replace('show','edit');
            $(this).find('.attachmend_icon').addClass('item_del_link');
        });
        my_table.find('.attachmend_line:last').show();
        var parent_hideble = my_table.parents('.hideble.attachmends');
        hideble.toggle(parent_hideble.find('a.item_hid_link.hided'));
        parent_hideble.show();
    },

    to_vieweble: function (my_table) {
        var c = 0;
        my_table.find('.attachmend_line[id*=edit], .attachmend_line[id*=new]').each(function(){
            this.id = this.id.replace(/(edit|new)/,'show');
            $(this).find('.attachmend_icon').removeClass('item_del_link');
            c += 1;
        });
        my_table.find('.attachmend_line:last').hide();
        var parent_hideble = my_table.parents('.hideble.attachmends');
        hideble.toggle(parent_hideble.find('a.item_hid_link:not(.hided)'));
        if (c == 0) {
            parent_hideble.hide();
        }
    },
    
    sending: function (self) {
        if (!attachmends._sending()) {
            return false;
        }
        if (!attachmends.func_after) {
            attachmends.func_after = arguments.callee.caller;
            attachmends.args_after = arguments.callee.caller.arguments;
            attachmends.self_after = self;
            page.shadow();
            $('body').append('<div class="attachmends_sending shadowed rounded">'+locmes.attachmends_sending+'</div>');
        }
        return true;
    },

    sended: function () {
        if (attachmends.func_after && !attachmends._sending()) {
            attachmends.func_after.apply(attachmends.self_after, attachmends.args_after);
            attachmends.func_after = null;
            attachmends.args_after = null;
            attachmends.self_after = null;
            $('body .attachmends_sending').remove();
            page.unshadow();
        }
    },

    _sending: function () {
        return $('#attachmends_form_container form').size() > 1;
    },

    _my_line: function (me) {
        var my_line = $(me).parents('.attachmend_line:first');
        my_line.id = my_line.attr('id');
        my_line.icon = my_line.find('.attachmend_icon');
        my_line.link = my_line.find('.attachmend_link');
        my_line.prog = my_line.find('.attachmend_prog');
        return my_line;
    },

    _my_table: function (me) {
        var my_table = $(me).parents('.attachmends_list:first');
        return my_table;
    },

    _my_owner: function (me) {
        var owner = RegExp('(new|edit|show)_([a-z_]+)_([0-9]*)_*attachmends_list', 'i').exec(attachmends._my_table(me).attr('id'))
        return {'mode':owner[1],'type':owner[2],'id':(owner[1]=='new'?'':owner[3])};
    },

    _build_form: function (uid, owner) {
        var form = $('#attachmends_form_container form:first');
        form.clone().insertBefore(form);
        form.children('input[name=uid]').val(uid);
        form.children('input[name=owner_id]').val(owner.id);
        form.children('input[name=owner_type]').val(owner.type);
        form.attr('target', uid);
        form.append('<iframe name="'+uid+'"></iframe>');
        return form;
    },

    _get_uid: function () {
        attachmends.uid += 1;
        return 'attachmend_' + attachmends.uid;
    }
}
$(attachmends.init);



//------------------------------------------------------------------------------
var page = {

    x: 0,
    y: 0,

    shadow: function () {
        $('body').append('<div class="page_shadow" style="position:fixed;top:0;left:0;width:1000%;height:1000%;background-color:#000;opacity:0.5;z-index:90;"></div>');
    },

    unshadow: function () {
        $('body div.page_shadow').remove();
    },

    save_position: function () {
        page.x = window.pageXOffset;
        page.y = window.pageYOffset;
        setTimeout(function(){window.scrollTo(page.x, page.y)}, 1);
    }
}



//------------------------------------------------------------------------------
var ssearch = {

    init: function () {
        $('form#top_search_form .value').live('mouseup',ssearch.del);
        $('a.tag').live('click',ssearch.add);
    },

    add: function () {
        var me = $(this);
        if (me.hasClass('tag')) {
            ssearch.form().append('<input type="hidden" name="s[]" value="'+me.text()+'"/>');
        }
        ssearch.go();
    },

    del: function () {
        $(this).prev('input').remove();
        ssearch.go();
    },

    page: function (p) {
        var form = ssearch.form();
        form.find('input[name="p"]').remove();
        form.append('<input type="hidden" name="p" value="'+p+'" />');
        ssearch.go();
    },

    go: function (me) {
        var form = ssearch.form();
        var for_remove = 'input[value=]';
        if (me) {
            me = $(me);
            if (me.attr('name') != 'r') {
                for_remove += ',select[name="r"]';
            }
            if (me.attr('name') != 'f') {
                if (form.find('select[name="f"]').val() == '') {
                    for_remove += ',select[name="f"]';
                }
            }
        }
        form.find(for_remove).removeAttr('name');
        form.submit();
    },

    form: function () {
        return $('form#top_search_form');
    }
}
$(ssearch.init);



//------------------------------------------------------------------------------
var do_export = {

    vcf: function (item, items, id) {
        do_export._do(item, items, id, 'vcf');
    },

    csv: function (item, items, id) {
        do_export._do(item, items, id, 'csv');
    },

    xml: function (item, items, id) {
        do_export._do(item, items, id, 'xml');
    },

    _do: function (item, items, id, type) {
        var href = "/" + items + "/export?type=" + type;
        if (!id) {
            var lines = $("[id^="+item+"_line_]");
            if (lines.size() > 0 ) {
                var efi = lines.find(":checkbox.mass_oper:checked");
                if (efi.size() == 0) {
                    efi = lines.find(":checkbox.mass_oper");
                }
                if (efi.size() > 0) {
                    efi.each(function(k,e){href += '&ids[]=' + e.value});
                    document.location.href = href;
                }
            }
        } else {
            document.location.href = href + '&ids[]=' + id;
        }
        $('#' + item + '_container').hide();
        $('#' + items + '_list_container').show();
        mass._sel_non(items);
        left_menu.correct();
    }
}



//------------------------------------------------------------------------------
var scheme = {

    select: function (me, v) {
        $('.scheme_item').removeClass('active');
        $(me).addClass('active');
        $(me).parents('form').find('input[name="scheme[id]"]').val(v);
    }
}


//------------------------------------------------------------------------------
var quick_info = {

    curr_line : null,
    last_line : null,
    position  : null,
    show_tid  : null,
    show_fade : 200,
    show_wait : 600,
    hide_tid  : null,
    hide_fade : 300,
    hide_wait : 1000,

    init: function () {
        $('tr.item_line').
            live('mouseover', quick_info.on_hover).
            live('mouseout mouseup', quick_info.on_out);
        $('div#quick_info').
            live('mouseover', quick_info.stop_hiding).
            live('mouseout', quick_info.on_out);
        $(window).bind('scroll', quick_info.set_pos);
        quick_info.position = getAbsolutePositionById('quick_info');
    },

    set_pos: function () {
        var s = $('#quick_info');
        var dy = $(window).scrollTop();
        if (dy + 8 > quick_info.position.y) {
            s.css({
                'position':'fixed',
                'top':'8px'
            });
        } else {
            s.css({
                'position':'relative',
                'top':'0'
            });
        }
    },

    stop_hiding: function () {
        quick_info._set_hide_timer(null);
        var me = $(this);
        if (me.css('opacity') != 1)
            me.stop().css('opacity',1);
    },

    on_hover: function () {
        if (quick_info.last_line == this) {
            quick_info._set_hide_timer(null);
        } else {
            quick_info.curr_line = this;
            quick_info._set_show_timer(true);
        }
    },

    on_out: function () {
        quick_info._set_show_timer(null);
        quick_info._set_hide_timer(true);
    },

    hide: function () {
        quick_info._set_show_timer(null);
        quick_info._set_hide_timer(null);
        quick_info.last_line = null;
        quick_info._visible().fadeOut(quick_info.hide_fade);
    },

    show: function (id) {
        quick_info._set_show_timer(null);
        var e = quick_info._container().find('#'+id);
        if (!e.hasClass('empty')) {
            quick_info._set_hide_timer(null);
            quick_info._visible().hide();
            e.fadeIn(quick_info.show_fade);
        }
    },

    request: function () {
        quick_info.last_line = quick_info.curr_line;
        var ln  = $(quick_info.curr_line);
        var cns = ln.parents('table[class$=_table]:first').attr('class').match(/(\w+)_table/)[1];
        var arr = ln.attr('id').match(/^(.+)_line_(\d+)$/);
        var id  = arr[2];
        var html_id = 'qi_' + arr[1] + '_' + id;
        if (quick_info.cache.has(html_id)) {
            quick_info.show(html_id);
        } else {
            $.ajax({
                url      : '/'+cns+'/'+id+'/quick_info',
                type     : 'get',
                dataType : 'script'});
        }
    },

    _container: function () {
        return $('div#quick_info');
    },

    _visible: function () {
        return $('div.quick_info:visible');
    },

    _set_hide_timer: function (v) {
        if (quick_info.hide_tid) {
            clearTimeout(quick_info.hide_tid);
        }
        if (v) {
            quick_info.hide_tid = setTimeout(quick_info.hide, quick_info.hide_wait);
        } else {
            quick_info.hide_tid = null;
        }
    },

    _set_show_timer: function (v) {
        if (quick_info.show_tid) {
            clearTimeout(quick_info.show_tid);
        }
        if (v) {
            quick_info.show_tid = setTimeout(quick_info.request, quick_info.show_wait);
        } else {
            quick_info.show_tid = null;
        }
    },

    cache: {
        
        has: function (id) {
            return quick_info._container().find('#'+id).size() != 0;
        },

        clear: function () {
            quick_info._container().empty();
        }
    }
}
$(quick_info.init);



//------------------------------------------------------------------------------
var left_menu = {

    last_pressed  : null,
    mass_selector : '.central_container > .items_list_container > table > tbody > .item_line > .item_opers .mass_oper:checkbox',
    position      : null,

    init: function () {
        $(left_menu.mass_selector).live('click', left_menu.correct)
        $(window).bind('scroll resize', left_menu.set_pos);
        left_menu.position = getAbsolutePositionById('left_menu_container');
    },

    set_pos: function () {
        var s = $('#left_menu_container');
        var u = s.find('.page_up a');
        var dy = $(window).scrollTop();
        var w = s.parents().first().width();
        if (dy + 8 > left_menu.position.y) {
            s.css({
                'position':'fixed',
                'top':'8px',
                'width':w
            });
            u.show();
        } else {
            s.css({
                'position':'relative',
                'top':'0',
                'width':w
            });
            u.hide();
        }
    },

    correct: function (e) {
        var empty = true;
        var lmc = $('#left_menu_container .context_buttons');
        var lib = $('#left_menu_item_buttons');
        var lmb = $('#left_menu_mass_buttons');
        if ($('.central_container > .items_list_container').is(':visible')) {
            lmb.show();
            lib.hide();
            var cnt = $(left_menu.mass_selector).filter(':checked').size();
            if (cnt > 0) {
                lmc.find('.select_counter span').text(cnt);
                empty = false;
            }
        } else {
            lib.show();
            lmb.hide();
            empty = lib.children().size() == 0;
        }
        if (!empty) {
            lmc.show();
        } else {
            lmc.hide();
        }
        var me = $(this);
        if (me.attr('type') == 'checkbox') {
            if (me.is(':checked')) {
                if (e && e.shiftKey && left_menu.last_pressed && left_menu.last_pressed != this) {
                    var cb = $(left_menu.mass_selector);
                    var i1 = cb.index(left_menu.last_pressed);
                    var i2 = cb.index(this);
                    if (i1 > i2) {
                        i1 = i1 + i2;
                        i2 = i1 - i2;
                        i1 = i1 - i2;
                    }
                    for (var i = i1 + 1; i < i2; i++) {
                        $(cb[i]).attr('checked','1');
                    }
                    setTimeout(left_menu.correct, 1);
                }
                left_menu.last_pressed = this;
            } else {
                left_menu.last_pressed = false;
            }
        }
    }
}
$(left_menu.init);



//------------------------------------------------------------------------------
var datepkr = {
    show_hide: function (me, hid) {
        var dp = $('#'+hid+'_datepicker');
        me = $(me);
        if (me.find(':last-child').is(':selected')) {
            var p = me.position();
            dp.css({'left':p.left,'top':p.top}).show();
        } else {
            datepkr.remove_picked_date(hid);
            dp.hide();
        }
    },

    remove_picked_date: function (hid) {
        $('#'+hid+'_picked_date').remove();
    },

    add_picked_date: function (hid, date_text) {
        datepkr.remove_picked_date(hid);
        $("<option id='"+hid+"_picked_date' selected value='"+date_text+" 23:59:59'>"+date_text+"</option>").insertBefore($("#"+hid+"_completion_select").find(":last-child").removeAttr("selected"));
    }
}



//------------------------------------------------------------------------------
var hint = {

    tid: null,

    init: function () {
        $('.have_hint').
            live('mouseover', hint.show).
            live('mouseout', hint.hide);
        $('.have_hint *, .hint_txt, .hint_pnt, .hint_bkg').
            live('mouseover', hint._set_timer).
            live('mouseout', hint.hide);
        $('.hint:not(.hinted)').
            addClass('.hinted').
            parent().
            addClass('have_hint');
    },

    show: function () {
        var b  = hint._bkg();

        var me = $(this);
        var mw = me.width();
        var mh = me.height();
        var mp = getAbsolutePosition(this);
        var mx = mp.x;
        var my = mp.y;

        var t  = hint._txt();
        t.html(me.find('.hint').html());
        var tw = t.width();
        var th = t.height();
        var tp = 10;

        var p  = hint._pnt();
        var pw = p.width();
        var ph = p.height();
        var dx = pw/2 + 2;

        var tx = mx + mw + dx;
        var ty = my;
        var px = tx - pw/2;
        var py = my + mh/2 - ph/2;

        if (tx + tw >= $(window).width()) {
            tx = mx - tw - dx;
            px = tx + tw + pw/2 + tp;
        }

        t.css({'left':tx,'top':ty});
        b.css({'left':tx,'top':ty,'height':th}).
            fadeIn(200, function(){hint._txt().fadeIn(200)});
        p.css({'top':py,'left':px}).
            fadeIn(200);
    },

    hide: function () {
        hint._set_timer(hint._hide, 500);
    },

    _hide: function () {
        hint._pnt().hide();
        hint._bkg().hide();
        hint._txt().hide();
    },

    _bkg: function () {return $('.hint_bkg')},
    _pnt: function () {return $('.hint_pnt')},
    _txt: function () {return $('.hint_txt')},

    _set_timer: function (fn, ms) {
        if (hint.tid) {
            clearTimeout(hint.tid);
            hint.tid = null;
        }
        if (fn) {
            hint.tid = setTimeout(fn, ms);
        }
    }
}
$(hint.init);



//------------------------------------------------------------------------------
$(function(){
    $('.item_opers a').
        live('focus',function(){
            $(this).addClass('hover');
        }).
        live('blur',function(){
            $(this).removeClass('hover');
        });
});
