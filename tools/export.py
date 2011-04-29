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


from bpy.props import *

fullFileName = ''
localResources = []

class mResource:
  def __init__(self, resource, formatName, fileName):
    if (resource != None):
      self.name = resource.name
    else:
      self.name = 'object'
    self.fileName = fileName
    self.rid = len(localResources)
    self.sid = len(localResources)
    self.fmt = formatName
    self.version = '1.0'
    localResources.append(self)

  def __repr__(self):
    return '    <resource resource:name="{0}" resource:id="{1}" resource:section="{2}" resource:format="{3}" resource:version="{4}" />\n'.format(self.name, self.rid, self.sid, self.fmt, self.version)

def getRelativeResourcePath(resource):
  orcf_data_path = '/home/philip/Delphi/orcf/data/'
  orcf_personal_data_path = '/home/philip/orcf-data/'
  
  resource = resource.replace(orcf_data_path, '')
  resource = resource.replace(orcf_personal_data_path, '')
  
  # for Windows compatibility
  resource = resource.replace('\\', '/')
  
  return resource


def getFullResourceName(resource):
  if (resource.library == None):
    return getRelativeResourcePath(fullFileName) + '/' + resource.name
  else:
    return getRelativeResourcePath(os.path.abspath(resource.library.filepath.replace('.blend', '.ocf'))) + '/' + resource.name

def isLocal(resource):
  return (resource.library == None)

def saveTexture(texture, directory):
  '''
  Create a TGA file that can be read by ocfgen
  '''
  if (texture.type == 'IMAGE'):
    if (texture.library == None):
      mResource(texture, 'tga', texture.image.filepath)
    else:
      print('Not saving linked texture {0}'.format(texture.name))
  else:
    print('{0}: Invalid texture type, must be Image'.format(texture.name))





def materialXML(material):
  # get texture slots
  textureSlot, bumpMapSlot = None, None
  for slot in material.texture_slots:
    if (slot != None):
      if (slot.use):
        if (textureSlot == None and slot.use_map_color_diffuse and slot.diffuse_color_factor > 0.0):
          textureSlot = slot
        if (bumpMapSlot == None and slot.use_map_normal and slot.normal_factor > 0.0):
          bumpMapSlot = slot

  # save xml string
  result = '<material>\n'
  result += '  <name>{0}</name>\n'.format(material.name)
  result += '  <color r="{0:.3f}" g="{1:.3f}" b="{2:.3f}" a="{3:.3f}" />\n'.format(material.diffuse_color[0], material.diffuse_color[1], material.diffuse_color[2], material.alpha)
  result += '  <specularity>{0:.3f}</specularity>\n'.format(material.specular_intensity)
  result += '  <hardness>{0}</hardness>\n'.format(material.specular_hardness)
  
  if (material.emit > 0.0):
    result += '  <emission r="{0:.3f}" g="{1:.3f}" b="{2:.3f}" falloff="{3:.3f}" />\n'.format(material.emit, material.emit, material.emit, material.get('emission_falloff', 2))

  if (material.raytrace_mirror.reflect_factor > 0.0 and material.raytrace_mirror.use):
    if (material.raytrace_mirror.distance > 0.0):
      result += '  <reflectivity>{0:.3f}</reflectivity>\n'.format(material.raytrace_mirror.reflect_factor)
    else:
      result += '  <reflectivity onlyenvironmentmap="true">{0:.3f}</reflectivity>\n'.format(material.raytrace_mirror.reflect_factor)
  
  if (textureSlot != None):
    result += '  <texture resource:name="{0}" />\n'.format(getFullResourceName(textureSlot.texture))
  
  if (bumpMapSlot != None):
    result += '  <bumpmap resource:name="{0}" />\n'.format(getFullResourceName(bumpMapSlot.texture))
  
  result += '</material>\n'
  return result

def saveMaterial(material, directory):
  '''
  Create an XML file with the material properties
  '''
  if (material.library == None):
    filepath = directory + os.path.basename(material.name) + '.xml'
    print('Saving material {0} to {1}'.format(material.name, filepath))
    matfile = open(filepath, mode='w', encoding='Latin-1')
    matfile.write(materialXML(material))
    matfile.close()
    mResource(material, 'xmlmaterial', filepath)
  else:
    print('Not saving linked material {0}'.format(material.name))



def lampXML(lamp):
  # object data for lamp
  objLamp = bpy.data.objects[lamp.name]
  
  result = '<light>\n'
  result += '  <name>{0}</name>\n'.format(lamp.name)
  result += '  <position x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" />\n'.format(objLamp.matrix_local[3][0], objLamp.matrix_local[3][2], objLamp.matrix_local[3][1])
  result += '  <color r="{0:.3f}" g="{1:.3f}" b="{2:.3f}" />\n'.format(lamp.color[0], lamp.color[1], lamp.color[2])
  result += '  <energy>{0:.3f}</energy>\n'.format(lamp.energy)
  result += '  <falloff>{0:.3f}</falloff>\n'.format(lamp.distance)
  result += '  <factor>{0:.3f}</factor>\n'.format(lamp.get('diffuse_factor', 0))
  
  if (lamp.shadow_method == 'NOSHADOW'):
    result += '  <castshadows>false</castshadows>\n'
  else:
    result += '  <castshadows>true</castshadows>\n'
  
  result += '</light>\n'
  return result

def saveLamp(lamp, directory):
  '''
  Create an XML file with the lamp properties
  '''
  if (lamp.type == 'POINT'):
    if (bpy.data.objects[lamp.name].parent != None):
      if (lamp.library == None):
        filepath = directory + os.path.basename(lamp.name) + '.xml'
        print('Saving lamp {0} to {1}'.format(lamp.name, filepath))
        lampfile = open(filepath, mode='w', encoding='Latin-1')
        lampfile.write(lampXML(lamp))
        lampfile.close()
        mResource(lamp, 'xmllight', filepath)
      else:
        print('Not saving linked lamp {0}'.format(lamp.name))
    else:
      print('Not saving lamp {0}: Lamps must be parented to a mesh'.format(lamp.name))
  else:
    print('{0}: Invalid lamp type, must be Point'.format(lamp.name))


def curveXML(curve):
  spline = None
  
  for currSpline in curve.splines:
    if (currSpline.type == 'BEZIER' and spline == None):
      spline = currSpline
  
  if (spline.use_cyclic_u):
    result = '<path closed="true">\n'
  else:
    result = '<path closed="false">\n'
  result += '  <name>{0}</name>\n'.format(curve.name)
  
  for point in spline.bezier_points:
    result += '  <point>\n'
    result += '    <cp1 x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" />\n'.format(point.handle_left[0], point.handle_left[2], point.handle_left[1])
    result += '    <pos x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" />\n'.format(point.co[0], point.co[2], point.co[1])
    result += '    <cp2 x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" />\n'.format(point.handle_right[0], point.handle_right[2], point.handle_right[1])
    result += '    <banking>{0:.3f}</banking>\n'.format(point.tilt * 57.29578)
    result += '  </point>\n'

  result += '</path>\n'
  return result

def saveCurve(curve, directory):
  '''
  Create an XML file with the curve properties
  '''
  if (curve.library == None):
    filepath = directory + os.path.basename(curve.name) + '.xml'
    print('Saving curve {0} to {1}'.format(curve.name, filepath))
    curvefile = open(filepath, mode='w', encoding='Latin-1')
    curvefile.write(curveXML(curve))
    curvefile.close()
    mResource(curve, 'xmlpath', filepath)
  else:
    print('Not saving linked curve {0}'.format(curve.name))


def boneXML(bone):
  result = '    <bone>\n'
  result += '      <name>{0}</name>\n'.format(bone.name)
  # TODO: work on this
  result += '      <position x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" />\n'.format(0, 0, 0)
  result += '      <matrix>\n'
  if (bone.parent == None):
    result += '        <row x="1" y="0" z="0" w="{0:.3f}" />\n'.format(bone.head_local[0])
    result += '        <row x="0" y="1" z="0" w="{0:.3f}" />\n'.format(bone.head_local[2])
    result += '        <row x="0" y="0" z="1" w="{0:.3f}" />\n'.format(bone.head_local[1])
  else:
    result += '        <row x="1" y="0" z="0" w="{0:.3f}" />\n'.format(bone.head_local[0] - bone.parent.head_local[0])
    result += '        <row x="0" y="1" z="0" w="{0:.3f}" />\n'.format(bone.head_local[2] - bone.parent.head_local[2])
    result += '        <row x="0" y="0" z="1" w="{0:.3f}" />\n'.format(bone.head_local[1] - bone.parent.head_local[1])
  result += '        <row x="0" y="0" z="0" w="1" />\n'
  result += '      </matrix>\n'
  
  for child in bone.children:
    result += boneXML(child)

  pathName = bone.get('path_name', '')
  path = None
  if (pathName != ''):
    path = bpy.data.curves[pathName]
  if (path != None):
    result += '      <path resource:name="{0}" followbanking="{1}" followorientation="{2}" progress="{3:.3f}" />\n'.format(getFullResourceName(path), bone.get('follow_banking', 'false'), bone.get('follow_orientation', 'false'), bone.get('path_offset', 0))
  
  result += '    </bone>\n'
  return result


def armatureXML(armature):
  result = '  <armature>\n'
  result += '    <name>{0}</name>\n'.format(armature.name)
  
  for bone in armature.bones:
    if (bone.parent == None):
      result += boneXML(bone)
  
  result += '  </armature>\n'
  return result

class mVertex:
  def __init__(self):
    self.position = [0, 0, 0]
    self.usefacenormal = True
    
  def __repr__(self):
    if (self.usefacenormal):
      result = '        <vertex usefacenormal="true">\n'
    else:
      result = '        <vertex usefacenormal="false">\n'
    result += '          <position x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" />\n'.format(self.position[0], self.position[2], self.position[1])
    result += '        </vertex>\n'
    return result

class mTexVertex:
  def __init__(self):
    self.position = [0, 0]

  def __repr__(self):
    result = '        <tvert x="{0:.3f}" y="{1:.3f}" />\n'.format(self.position[0], self.position[1])
    return result

class mFace:
  def __init__(self):
    self.tindices = [0, 0, 0]
    self.vindices = [0, 0, 0]

  def __repr__(self):
    result = '        <face>\n'
    result += '          <index vid="{0}" tid="{1}" />\n'.format(self.vindices[2], self.tindices[2])
    result += '          <index vid="{0}" tid="{1}" />\n'.format(self.vindices[1], self.tindices[1])
    result += '          <index vid="{0}" tid="{1}" />\n'.format(self.vindices[0], self.tindices[0])
    result += '        </face>\n'
    return result

def geometryXML(mesh):
  objMesh = bpy.data.objects[mesh.name]

  tmpVertices = []
  tmpTexVertices = []
  tmpFaces = []

  uvTexture = None
  for u in mesh.uv_textures:
    if (uvTexture == None and u.active):
      uvTexture = u

  for tv in uvTexture.data:
    t = mTexVertex()
    t.position = tv.uv1
    tmpTexVertices.append(t)
    t = mTexVertex()
    t.position = tv.uv2
    tmpTexVertices.append(t)
    t = mTexVertex()
    t.position = tv.uv3
    tmpTexVertices.append(t)

  for vert in mesh.vertices:
    v = mVertex()
    v.usefacenormal = True
    v.position = vert.co
    v.position = [vert.co[0] * objMesh.matrix_local[0][0] + vert.co[1] * objMesh.matrix_local[1][0] + vert.co[2] * objMesh.matrix_local[2][0],
                  vert.co[0] * objMesh.matrix_local[0][1] + vert.co[1] * objMesh.matrix_local[1][1] + vert.co[2] * objMesh.matrix_local[2][1],
                  vert.co[0] * objMesh.matrix_local[0][2] + vert.co[1] * objMesh.matrix_local[1][2] + vert.co[2] * objMesh.matrix_local[2][2]]
    tmpVertices.append(v)

  c = 0
  for face in mesh.faces:
    f = mFace()
    f.tindices = [3 * c, 3 * c + 1, 3 * c + 2]
    f.vindices = [face.vertices[0], face.vertices[1], face.vertices[2]]
    tmpFaces.append(f)
    
    tmpVertices[face.vertices[0]].usefacenormal &= not(face.use_smooth)
    tmpVertices[face.vertices[1]].usefacenormal &= not(face.use_smooth)
    tmpVertices[face.vertices[2]].usefacenormal &= not(face.use_smooth)

    c += 1

  result = '      <vertices>\n'
  for v in tmpVertices:
    result += str(v)
  result += '      </vertices>\n'
  
  result += '      <texvertices>\n'
  for t in tmpTexVertices:
    result += str(t)
  result += '      </texvertices>\n'
  
  result += '      <faces>\n'
  for f in tmpFaces:
    result += str(f)
  result += '      </faces>\n'
  return result

def meshXML(mesh):
  objMesh = bpy.data.objects[mesh.name]
  
  result = '  <mesh>\n'
  result += '    <name>{0}</name>\n'.format(mesh.name)
  result += '    <material resource:name="{0}" />\n'.format(getFullResourceName(mesh.materials[0]))
  for lamp in bpy.data.lamps:
    objLamp = bpy.data.objects[lamp.name]
    if (objLamp.parent == objMesh):
      result += '    <light resource:name="{0}" x="{1:.3f}" y="{2:.3f}" z="{3:.3f}" />\n'.format(getFullResourceName(lamp), objLamp.matrix_local[3][0], objLamp.matrix_local[3][2], objLamp.matrix_local[3][1])
  result += '    <matrix>\n'
  result += '      <row x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" w="{3:.3f}" />\n'.format(1, 0, 0, objMesh.matrix_local[3][0])
  result += '      <row x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" w="{3:.3f}" />\n'.format(0, 1, 0, objMesh.matrix_local[3][2])
  result += '      <row x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" w="{3:.3f}" />\n'.format(0, 0, 1, objMesh.matrix_local[3][1])
  result += '      <row x="{0:.3f}" y="{1:.3f}" z="{2:.3f}" w="{3:.3f}" />\n'.format(objMesh.matrix_local[0][3], objMesh.matrix_local[2][3], objMesh.matrix_local[1][3], objMesh.matrix_local[3][3])
  result += '    </matrix>\n'
  result += '    <mindist>{0:.3f}</mindist>\n'.format(mesh.get('min_dist', -10000))
  result += '    <maxdist>{0:.3f}</maxdist>\n'.format(mesh.get('max_dist', 10000))
  result += '    <geometry>\n'
  result += geometryXML(mesh)
  result += '    </geometry>\n'
  result += '  </mesh>\n'
  return result


def objectXML():
  result = '<object>\n'
  
  for armature in bpy.data.armatures:
    result += armatureXML(armature)

  for mesh in bpy.data.meshes:
    result += meshXML(mesh)
  
  result += '</object>\n'
  return result


def saveObject(directory):
  '''
  Create an XML file with armatures and meshes
  '''
  filepath = directory + 'object.xml'
  print('Saving meshes and armatures to {0}'.format(filepath))
  objectfile = open(filepath, mode='w', encoding='Latin-1')
  objectfile.write(objectXML())
  mResource(None, 'xmlobject', filepath)


def resourceTableXML():
  author = 'Unknown author'
  for world in bpy.data.worlds:
    if (world.get('author', '') != ''):
      author = world.get('author', 'Unknown author')
  
  result = '<?xml version="1.0" encoding="UTF-8"?>\n';
  result += '<ocf resource:version="1.0" type="resource" author="{0}">\n'.format(author)
  result += '  <resources>\n'
  for resource in localResources:
    result += str(resource)
  result += '  </resources>\n'
  result += '</ocf>\n'
  return result;

def saveResourceTable(directory):
  filepath = os.path.splitext(fullFileName)[0] + ".xml"
  print('Saving resource table to {0}'.format(filepath))
  resourcetablefile = open(filepath, mode='w', encoding='Latin-1')
  resourcetablefile.write(resourceTableXML())
  resourcetablefile.close()

def runOCFgen(fileName):
  ocfgen_exe = '/home/philip/Delphi/orcf/tools/ocfgen'
  if (ocfgen_exe != ''):
    print('Generating OCF file {0}'.format(fileName))
    cmd = ocfgen_exe + ' -x {0}'.format(os.path.splitext(fileName)[0] + '.xml')
    for resource in localResources:
      cmd += ' -b {0}'.format(resource.fileName)
    cmd += ' -o {0}'.format(fileName)
    os.system(cmd)
    scriptfile = open(os.path.splitext(fileName)[0] + '.sh', mode='w', encoding='Latin-1')
    scriptfile.write(cmd)
    scriptfile.close()
  return True

def writeFiles(fileName):
  global fullFileName
  fullFileName = fileName
  directory = os.path.dirname(fileName) + '/'

  # Save textures as TGA files by name
  for texture in bpy.data.textures:
    saveTexture(texture, directory)

  # Save Materials
  for material in bpy.data.materials:
    saveMaterial(material, directory)

  # Save lamps
  for lamp in bpy.data.lamps:
    saveLamp(lamp, directory)

  # Save curves
  for curve in bpy.data.curves:
    saveCurve(curve, directory)

  # Save object itself
  saveObject(directory)

  # Save resource table
  saveResourceTable(directory)

  # Compile OCF file
  runOCFgen(fileName)

  print('Saved all data.')




class EXPORT_OT_ocfl(bpy.types.Operator):
  bl_idname = "export_scene.ocf"
  bl_label = "Export OCF"

  filepath = StringProperty(name="File Path", description="File path used for exporting the OCF file", maxlen= 1024, default= "")
  def execute(self, context):
    global localResources
    localResources = []

    # remove relative file paths
    bpy.ops.file.make_paths_absolute()
    
    # split all quads to single triangles
    if bpy.context.mode == 'OBJECT':
      bpy.ops.object.editmode_toggle()
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.mesh.quads_convert_to_tris()
    bpy.ops.object.editmode_toggle()
    
    writeFiles(self.properties.filepath)
    
    return {'FINISHED'}

  def invoke(self, context, event):
    self.execute(context)
    return {'FINISHED'}

def menu_func(self, context):
  default_path = os.path.splitext(bpy.data.filepath)[0] + ".ocf"
  self.layout.operator(EXPORT_OT_ocfl.bl_idname, text="OCF Source Files").filepath = default_path

def register():
  bpy.utils.register_module(__name__)
  bpy.types.INFO_MT_file_export.append(menu_func)

def unregister():
  bpy.utils.unregister_module(__name__)
  bpy.types.INFO_MT_file_export.remove(menu_func)

if __name__ == '__main__':
  register()
