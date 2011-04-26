# ***** BEGIN GPL LICENSE BLOCK *****
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software Foundation,
# Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#
# ***** END GPL LICENCE BLOCK *****
# vMC
# **********************************
bl_info = {
    "name": "ORCF Object Export",
    "author": "Philip Rebohle",
    "version": (0, 0, 1),
    "blender": (2, 5, 7),
    "api": 35622,
    "location": "File > Export > OCF Source Files",
    "description": "Export objects to XML and TGA files",
    "warning": "",
    "wiki_url": "",
    "tracker_url": "",
    "category": "Import-Export"
}

import os
import bpy


def menu_func(self, context):
    # append .ase to filepath
    default_path = os.path.splitext(bpy.data.filepath)[0] + ".ocf"
    self.layout.operator(EXPORT_OT_asel.bl_idname, text="ORCF Object Export").filepath = default_path

def register():
    bpy.utils.register_module(__name__)
    bpy.types.INFO_MT_file_export.append(menu_func)

def unregister():
    bpy.utils.unregister_module(__name__)
    bpy.types.INFO_MT_file_export.remove(menu_func)

if __name__ == '__main__':
    register()
