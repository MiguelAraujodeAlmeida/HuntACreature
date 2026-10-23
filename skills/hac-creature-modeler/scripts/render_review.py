"""Render a creature review sheet without changing the source scene.

In Blender: import render_review; render_review.render_review("Species_Base", output_dir,
"Species_Base_v01"). For a quick tool check pass cell_size=96. The temporary
preview scene and objects are removed; the source .blend is never saved here.
"""

from array import array
import math
from pathlib import Path

import bpy
from mathutils import Vector


VIEWS = (
    ("front", (0, -1, 0), False),
    ("side_right", (1, 0, 0), False),
    ("back", (0, 1, 0), False),
    ("side_left", (-1, 0, 0), False),
    ("threeq_front", (1, -1, 0.28), True),
    ("threeq_back", (1, 1, 0.28), True),
    ("threeq_front_left", (-1, -1, 0.28), True),
    ("top", (0, 0, 1), False),
    ("sil_front", (0, -1, 0), False),
    ("sil_side_right", (1, 0, 0), False),
    ("sil_back", (0, 1, 0), False),
    ("sil_threeq_front", (1, -1, 0.28), False),
)


def _bounds(collection):
    positions = []
    for obj in collection.all_objects:
        if obj.type != "MESH" or obj.hide_render:
            continue
        positions.extend(obj.matrix_world @ Vector(corner)
                         for corner in obj.bound_box)
    if not positions:
        raise ValueError("Creature collection contains no renderable meshes")
    minimum = Vector(tuple(min(p[i] for p in positions) for i in range(3)))
    maximum = Vector(tuple(max(p[i] for p in positions) for i in range(3)))
    return minimum, maximum


def _create_cube(collection, name, center, dimensions, material):
    x, y, z = (value/2 for value in dimensions)
    coords = [(-x,-y,-z), (x,-y,-z), (x,y,-z), (-x,y,-z),
              (-x,-y,z), (x,-y,z), (x,y,z), (-x,y,z)]
    faces = [(0,3,2,1), (4,5,6,7), (0,1,5,4), (1,2,6,5),
             (2,3,7,6), (3,0,4,7)]
    mesh = bpy.data.meshes.new(name)
    mesh.from_pydata(coords, [], faces)
    mesh.update()
    mesh.materials.append(material)
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.location = center
    return obj


def _scale_avatar(scene, x):
    collection = bpy.data.collections.new("ScaleRef_NoExport")
    scene.collection.children.link(collection)
    material = bpy.data.materials.new("ScaleRef_Gray")
    material.diffuse_color = (0.45, 0.49, 0.53, 1)
    material.use_nodes = True
    material.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = material.diffuse_color
    pieces = (
        ("Torso", (x, 0, 3.0), (1.8, 0.8, 2.0)),
        ("Head", (x, 0, 4.6), (1.2, 1.0, 1.2)),
        ("LeftLeg", (x-0.48, 0, 1.0), (0.7, 0.8, 2.0)),
        ("RightLeg", (x+0.48, 0, 1.0), (0.7, 0.8, 2.0)),
        ("LeftArm", (x-1.22, 0, 2.95), (0.62, 0.8, 1.9)),
        ("RightArm", (x+1.22, 0, 2.95), (0.62, 0.8, 1.9)),
    )
    for name, center, dimensions in pieces:
        _create_cube(collection, "ScaleRef_" + name, center, dimensions, material)
    return collection


def _preview_scene(creature):
    scene = bpy.data.scenes.new("HAC_Review_Temporary")
    scene.collection.children.link(creature)
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.film_transparent = False
    _set_eevee(scene)
    scene.view_settings.view_transform = "Standard"
    world = bpy.data.worlds.new("HAC_Review_World")
    world.use_nodes = True
    background = world.node_tree.nodes.get("Background")
    background.inputs["Color"].default_value = (0.78, 0.84, 0.92, 1)
    background.inputs["Strength"].default_value = 0.5
    scene.world = world
    camera_data = bpy.data.cameras.new("HAC_Review_Camera")
    camera = bpy.data.objects.new("HAC_Review_Camera", camera_data)
    scene.collection.objects.link(camera)
    scene.camera = camera
    sun_data = bpy.data.lights.new("HAC_Review_Sun", "SUN")
    sun_data.energy = 4.0
    sun_data.angle = math.radians(8)
    sun = bpy.data.objects.new("HAC_Review_Sun", sun_data)
    scene.collection.objects.link(sun)
    sun.rotation_euler = tuple(math.radians(v) for v in (50, 0, -35))
    return scene, camera


def _set_eevee(scene):
    for engine in ("BLENDER_EEVEE", "BLENDER_EEVEE_NEXT"):
        try:
            scene.render.engine = engine
            return
        except (TypeError, ValueError):
            pass
    raise RuntimeError("This Blender build does not expose EEVEE")


def _aim(camera, target, direction, span, perspective=False):
    direction = Vector(direction).normalized()
    camera.location = target + direction * (span * 4.5)
    camera.rotation_euler = (target - camera.location).to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "PERSP" if perspective else "ORTHO"
    if perspective:
        camera.data.lens = 120
    else:
        camera.data.ortho_scale = span * 1.35


def _stitch(paths, destination, cell_size):
    width, height = cell_size * 4, cell_size * 3
    canvas = array("f", [1.0]) * (width * height * 4)
    for index, path in enumerate(paths):
        image = bpy.data.images.load(str(path), check_existing=False)
        try:
            if tuple(image.size) != (cell_size, cell_size):
                raise ValueError(f"Unexpected render size: {image.size}")
            pixels = array("f", [0.0]) * (cell_size * cell_size * 4)
            image.pixels.foreach_get(pixels)
            column, row = index % 4, index // 4
            for y in range(cell_size):
                src = y * cell_size * 4
                dst = ((2-row)*cell_size + y) * width * 4 + column*cell_size*4
                canvas[dst:dst+cell_size*4] = pixels[src:src+cell_size*4]
        finally:
            bpy.data.images.remove(image)
    sheet = bpy.data.images.new("HAC_Review_Sheet", width=width, height=height, alpha=True)
    try:
        sheet.pixels.foreach_set(canvas)
        sheet.filepath_raw = str(destination)
        sheet.file_format = "PNG"
        sheet.save()
    finally:
        bpy.data.images.remove(sheet)


def render_review(collection_name, output_dir, stem, cell_size=700,
                  scale_size=(900, 700)):
    creature = bpy.data.collections.get(collection_name)
    if not creature:
        raise ValueError(f"Collection not found: {collection_name}")
    output = Path(output_dir)
    output.mkdir(parents=True, exist_ok=True)
    scene, camera = _preview_scene(creature)
    minimum, maximum = _bounds(creature)
    target = (minimum + maximum) / 2
    span = max(*(maximum[i]-minimum[i] for i in range(3)), 0.5)
    paths = []
    try:
        for name, direction, perspective in VIEWS:
            silhouette = name.startswith("sil_")
            if silhouette:
                scene.render.engine = "BLENDER_WORKBENCH"
            else:
                _set_eevee(scene)
            if silhouette:
                shading = scene.display.shading
                shading.light = "FLAT"
                shading.color_type = "SINGLE"
                shading.single_color = (0, 0, 0)
                shading.background_type = "WORLD"
                scene.world.color = (1, 1, 1)
            scene.render.resolution_x = cell_size
            scene.render.resolution_y = cell_size
            _aim(camera, target, direction, span, perspective)
            path = output / f"{name}.png"
            scene.render.filepath = str(path)
            bpy.ops.render.render(scene=scene.name, write_still=True)
            paths.append(path)

        avatar = _scale_avatar(scene, maximum.x + 2.1)
        try:
            _set_eevee(scene)
            scene.render.resolution_x, scene.render.resolution_y = scale_size
            comparison_min = Vector((minimum.x, minimum.y, min(minimum.z, 0)))
            comparison_max = Vector((maximum.x + 3.6, maximum.y, max(maximum.z, 5.2)))
            comparison_target = (comparison_min + comparison_max) / 2
            comparison_span = max(comparison_max.x-comparison_min.x,
                                  comparison_max.z-comparison_min.z)
            _aim(camera, comparison_target, (0, -1, 0), comparison_span)
            scene.render.filepath = str(output / "scale_vs_avatar.png")
            bpy.ops.render.render(scene=scene.name, write_still=True)
        finally:
            for obj in list(avatar.objects):
                bpy.data.objects.remove(obj, do_unlink=True)
            bpy.data.collections.remove(avatar)
        sheet_path = output / f"{stem}_sheet.png"
        _stitch(paths, sheet_path, cell_size)
        return {"sheet": str(sheet_path), "scale": str(output / "scale_vs_avatar.png"),
                "views": [str(path) for path in paths]}
    finally:
        world = scene.world
        camera_data = camera.data
        light_data = next((obj.data for obj in scene.collection.objects
                           if obj.type == "LIGHT"), None)
        bpy.data.scenes.remove(scene)
        if camera.name in bpy.data.objects:
            bpy.data.objects.remove(camera, do_unlink=True)
        if camera_data.name in bpy.data.cameras:
            bpy.data.cameras.remove(camera_data)
        if light_data and light_data.name in bpy.data.lights:
            bpy.data.lights.remove(light_data)
        if world and world.name in bpy.data.worlds:
            bpy.data.worlds.remove(world)
