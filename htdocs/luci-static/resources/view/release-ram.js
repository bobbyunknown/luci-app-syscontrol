/*
 * This is open source software, licensed under the MIT License.
 *
 * Copyright (C) 2024 BobbyUnknown
 *
 * Description:
 * This software provides a RAM release scheduling application for OpenWrt.
 * The application allows users to configure and automate the process of 
 * releasing RAM on their OpenWrt router at specified intervals, helping
 * to optimize system performance and resource management through a 
 * user-friendly web interface.
 */


'use strict';
'require fs';
'require view';

return view.extend({
 handleSaveApply: null,
 handleSave: null,
 handleReset: null,

 load: function() {
  return Promise.all([
   L.resolveDefault(fs.exec('/bin/sync', null), null),
   L.resolveDefault(fs.exec('/sbin/sysctl', ['-w', 'vm.drop_caches=3']), null),
  ]);
 },

 render: function () {
  window.location.href = '/cgi-bin/luci/admin/system/syscontrol';
 }
});
