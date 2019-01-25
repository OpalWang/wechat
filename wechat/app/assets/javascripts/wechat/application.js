// This is a manifest file that'll be compiled into application.js, which will include all the files
// listed below.
//
// Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
// or any plugin's vendor/assets/javascripts directory can be referenced here using a relative path.
//
// It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
// compiled file.
//
// Read Sprockets README (https://github.com/rails/sprockets#sprockets-directives) for details
// about supported directives.
//
//= require jquery.min
//= require jquery.turbolinks
//= require jquery_ujs
//= require jquery.remotipart
//= require bootstrap.min
//= require bootstrap-select.min
//= require jquery.datetimepicker
//= require ckeditor/init
//= require icheck.min
//= require bootstrap-toggle.min
//= require jquery-ui
//= require validate.jquery
//= require turbolinks

function checkAll(object)
{
   var order_id = document.getElementsByName("parcel_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllBI(object)
{
   var order_id = document.getElementsByName("bi_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllFB(object)
{
   var order_id = document.getElementsByName("fb_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllCI(object)
{
   var order_id = document.getElementsByName("ci_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAll1(object)
{
   var order_id = document.getElementsByName("flight_time[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllForDelete(object)
{
   var order_id = document.getElementsByName("pcl_delete_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllForBi(object)
{
   var order_id = document.getElementsByName("bi_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllForExtraPay(object)
{
   var order_id = document.getElementsByName("extra_pay_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllForRetourParcel(object)
{
   var order_id = document.getElementsByName("rparcel_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllForMaterialOrder(object)
{
   var order_id = document.getElementsByName("morder_id[]");
   var length = order_id.length;
   var checked = object.checked;
   //alert(checked)
   for (var i = 0; i < length; i++)
   {
     order_id[i].checked=checked;
   }
}

function checkAllForAirwaybill(object)
{
    var obj_id = document.getElementsByName("airwaybill_ids[]");
    var length = obj_id.length;
    var checked = object.checked;
    //alert(checked)
    for (var i = 0; i < length; i++)
    {
        obj_id[i].checked=checked;
    }
}

Date.prototype.format = function(fmt) { 
     var o = { 
        "M+" : this.getMonth()+1,                 //月份 
        "d+" : this.getDate(),                    //日 
        "h+" : this.getHours(),                   //小时 
        "m+" : this.getMinutes(),                 //分 
        "s+" : this.getSeconds(),                 //秒 
        "q+" : Math.floor((this.getMonth()+3)/3), //季度 
        "S"  : this.getMilliseconds()             //毫秒 
    }; 
    if(/(y+)/.test(fmt)) {
            fmt=fmt.replace(RegExp.$1, (this.getFullYear()+"").substr(4 - RegExp.$1.length)); 
    }
     for(var k in o) {
        if(new RegExp("("+ k +")").test(fmt)){
             fmt = fmt.replace(RegExp.$1, (RegExp.$1.length==1) ? (o[k]) : (("00"+ o[k]).substr((""+ o[k]).length)));
         }
     }
    return fmt; 
}  
