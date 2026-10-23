"""Reusable Blender construction primitives for Hunt A Creature art.

All dimensions and locations are expressed in design units. ``scale`` is applied
exactly once to mesh coordinates, placements and bevel widths. A design unit at
scale=1 is one Blender unit / one Roblox stud.
"""

import math

import bmesh
import bpy
from mathutils import Euler, Matrix


FINISHES = {
    "ToyMatte": (0.45, 0.0),
    "ToyGloss": (0.20, 0.0),
    "ToyMetal": (0.25, 0.70),
    "ToyGlow": (0.25, 0.0),
}


def srgb_to_linear(rgb):
    def channel(value):
        value = value / 255.0
        return value / 12.92 if value <= 0.04045 else ((value + 0.055) / 1.055) ** 2.4

    return tuple(channel(v) for v in rgb) + (1.0,)


def make_material(name, rgb, role="Main", finish="ToyMatte"):
    if finish not in FINISHES:
        raise ValueError(f"Unknown finish: {finish}")
    roughness, metallic = FINISHES[finish]
    color = srgb_to_linear(rgb)
    material = bpy.data.materials.new(name)
    material.diffuse_color = color
    material.roughness = roughness
    material.metallic = metallic
    material.use_nodes = True
    shader = material.node_tree.nodes.get("Principled BSDF")
    if shader:
        shader.inputs["Base Color"].default_value = color
        shader.inputs["Roughness"].default_value = roughness
        shader.inputs["Metallic"].default_value = metallic
        if finish == "ToyGlow":
            if "Emission Color" in shader.inputs:
                shader.inputs["Emission Color"].default_value = color
            if "Emission Strength" in shader.inputs:
                shader.inputs["Emission Strength"].default_value = 2.0
    material["ColorRole"] = role
    material["Finish"] = finish
    return material


class CreatureKit:
    def __init__(self, collection, scale=1.0):
        if scale <= 0:
            raise ValueError("scale must be positive")
        self.collection = collection
        self.scale = float(scale)

    def _location(self, location):
        return tuple(float(value) * self.scale for value in location)

    def _finish(self, name, bm, material=None, bevel=0.04, segments=1,
                angle=35, location=(0, 0, 0), rotation=(0, 0, 0), parent=None):
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        mesh = bpy.data.meshes.new(name)
        bm.to_mesh(mesh)
        bm.free()
        mesh.update()
        for face in mesh.polygons:
            face.use_smooth = False
        if material:
            mesh.materials.append(material)
        obj = bpy.data.objects.new(name, mesh)
        self.collection.objects.link(obj)
        obj.location = self._location(location)
        obj.rotation_euler = Euler(tuple(math.radians(v) for v in rotation), "XYZ")
        if parent:
            obj.parent = parent
        if material and "ColorRole" in material:
            obj["ColorRole"] = material["ColorRole"]
            obj["Finish"] = material.get("Finish", "ToyMatte")
        if bevel > 0:
            modifier = obj.modifiers.new("Chamfer", "BEVEL")
            modifier.width = bevel * self.scale
            modifier.segments = segments
            modifier.limit_method = "ANGLE"
            modifier.angle_limit = math.radians(angle)
        return obj

    def empty(self, name, location=(0, 0, 0), rotation=(0, 0, 0), parent=None):
        obj = bpy.data.objects.new(name, None)
        self.collection.objects.link(obj)
        obj.empty_display_type = "PLAIN_AXES"
        obj.empty_display_size = 0.25 * self.scale
        obj.location = self._location(location)
        obj.rotation_euler = Euler(tuple(math.radians(v) for v in rotation), "XYZ")
        if parent:
            obj.parent = parent
        return obj

    def frustum(self, name, bottom_width, bottom_depth, top_width, top_depth, height,
                *, top_shift=(0, 0), material=None, bevel=0.05, segments=1,
                angle=35, location=(0, 0, 0), rotation=(0, 0, 0), parent=None,
                origin_bottom=True):
        s = self.scale
        bw, bd, tw, td, h = [v * s for v in
                             (bottom_width, bottom_depth, top_width, top_depth, height)]
        shift_x, shift_y = (v * s for v in top_shift)
        z0 = 0 if origin_bottom else -h / 2
        z1 = z0 + h
        coords = [(-bw/2, -bd/2, z0), (bw/2, -bd/2, z0),
                  (bw/2, bd/2, z0), (-bw/2, bd/2, z0),
                  (-tw/2+shift_x, -td/2+shift_y, z1),
                  (tw/2+shift_x, -td/2+shift_y, z1),
                  (tw/2+shift_x, td/2+shift_y, z1),
                  (-tw/2+shift_x, td/2+shift_y, z1)]
        bm = bmesh.new()
        verts = [bm.verts.new(co) for co in coords]
        for indices in ((0, 3, 2, 1), (4, 5, 6, 7), (0, 1, 5, 4),
                        (1, 2, 6, 5), (2, 3, 7, 6), (3, 0, 4, 7)):
            bm.faces.new([verts[i] for i in indices])
        return self._finish(name, bm, material, bevel, segments, angle,
                            location, rotation, parent)

    def loft(self, name, rings, *, sides=4, material=None, bevel=0.05,
             segments=1, angle=35, location=(0, 0, 0), rotation=(0, 0, 0),
             parent=None):
        """Rings are (z, width/radius_x, depth/radius_y, shift_x, shift_y)."""
        if len(rings) < 2 or sides < 3:
            raise ValueError("loft requires at least two rings and three sides")
        s = self.scale
        bm = bmesh.new()
        built = []
        for z, x_extent, y_extent, shift_x, shift_y in rings:
            ring = []
            for i in range(sides):
                if sides == 4:
                    x, y = ((-x_extent/2, -y_extent/2),
                            (x_extent/2, -y_extent/2),
                            (x_extent/2, y_extent/2),
                            (-x_extent/2, y_extent/2))[i]
                else:
                    theta = 2 * math.pi * i / sides + math.pi / sides
                    x, y = math.cos(theta) * x_extent, math.sin(theta) * y_extent
                ring.append(bm.verts.new(((x + shift_x) * s,
                                          (y + shift_y) * s, z * s)))
            built.append(ring)
        bm.faces.new(list(reversed(built[0])))
        bm.faces.new(built[-1])
        for lower, upper in zip(built[:-1], built[1:]):
            for i in range(sides):
                j = (i + 1) % sides
                bm.faces.new((lower[i], lower[j], upper[j], upper[i]))
        return self._finish(name, bm, material, bevel, segments, angle,
                            location, rotation, parent)

    def poly_loft(self, name, rings, *, sides=8, **kwargs):
        return self.loft(name, rings, sides=sides, **kwargs)

    def diamond(self, name, width, depth, bottom_height, top_height, *,
                material=None, bevel=0.015, location=(0, 0, 0),
                rotation=(0, 0, 0), parent=None):
        s = self.scale
        coords = [(0, 0, -bottom_height*s), (0, 0, top_height*s),
                  (0, -depth*s/2, 0), (width*s/2, 0, 0),
                  (0, depth*s/2, 0), (-width*s/2, 0, 0)]
        bm = bmesh.new()
        verts = [bm.verts.new(co) for co in coords]
        for i in range(4):
            j = 2 + (i + 1) % 4
            a = 2 + i
            bm.faces.new((verts[0], verts[j], verts[a]))
            bm.faces.new((verts[a], verts[j], verts[1]))
        return self._finish(name, bm, material, bevel, 1, 25,
                            location, rotation, parent)

    def segmented_arc(self, name, radius, radial_thickness, depth, *,
                      arc_degrees=260, segments=8, material=None, bevel=0.02,
                      location=(0, 0, 0), rotation=(0, 0, 0), parent=None):
        if segments < 2 or radial_thickness <= 0 or radius <= radial_thickness/2:
            raise ValueError("invalid arc geometry")
        root = self.empty(name + "_Pivot", location, rotation, parent)
        span = math.radians(arc_degrees)
        inner, outer = radius-radial_thickness/2, radius+radial_thickness/2
        for index in range(segments):
            a0 = -span/2 + span*index/segments
            a1 = -span/2 + span*(index+1)/segments
            points = []
            for angle in (a0, a1):
                for radial in (inner, outer):
                    for y in (-depth/2, depth/2):
                        points.append((math.sin(angle)*radial*self.scale,
                                       y*self.scale,
                                       math.cos(angle)*radial*self.scale))
            bm = bmesh.new()
            v = [bm.verts.new(co) for co in points]
            for face in ((0, 1, 3, 2), (4, 6, 7, 5), (0, 4, 5, 1),
                         (2, 3, 7, 6), (0, 2, 6, 4), (1, 5, 7, 3)):
                bm.faces.new([v[i] for i in face])
            self._finish(f"{name}_Seg_{index:02d}", bm, material, bevel,
                         1, 30, parent=root)
        return root

    def stud(self, name, location, *, parent=None, material=None,
             radius=0.11, height=0.07, rotation=(0, 0, 0)):
        bm = bmesh.new()
        bmesh.ops.create_cone(
            bm, cap_ends=True, cap_tris=False, segments=12,
            radius1=radius*self.scale, radius2=radius*self.scale,
            depth=height*self.scale,
            matrix=Matrix.Translation((0, 0, height*self.scale/2)),
        )
        return self._finish(name, bm, material, 0.015, 1, 30,
                            location, rotation, parent)


def band_front(rings, lower_index, upper_index):
    """Return front-face (y, z) and pitch in degrees for a rectangular loft."""
    z0, _, depth0, _, shift0 = rings[lower_index]
    z1, _, depth1, _, shift1 = rings[upper_index]
    y0, y1 = shift0-depth0/2, shift1-depth1/2
    return (y0, z0), math.degrees(math.atan2(y0-y1, z1-z0))


def export_fbx_collection(collection, filepath):
    """Export creature meshes/empties only, restoring the user's selection."""
    selected = list(bpy.context.selected_objects)
    active = bpy.context.view_layer.objects.active
    try:
        bpy.ops.object.select_all(action="DESELECT")
        objects = [obj for obj in collection.all_objects if obj.type in {"MESH", "EMPTY"}]
        if not objects:
            raise ValueError("Creature collection is empty")
        for obj in objects:
            obj.select_set(True)
        bpy.context.view_layer.objects.active = objects[0]
        bpy.ops.export_scene.fbx(
            filepath=str(filepath), use_selection=True,
            object_types={"MESH", "EMPTY"}, use_custom_props=True,
            add_leaf_bones=False, apply_unit_scale=True,
        )
    finally:
        bpy.ops.object.select_all(action="DESELECT")
        for obj in selected:
            if obj.name in bpy.data.objects:
                obj.select_set(True)
        if active and active.name in bpy.data.objects:
            bpy.context.view_layer.objects.active = active
