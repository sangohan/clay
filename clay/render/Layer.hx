package clay.render;


import kha.graphics4.Graphics;

import clay.render.types.BlendMode;
import clay.render.types.BlendEquation;
import clay.render.DisplayObject;
import clay.render.Camera;
import clay.resources.Texture;
import clay.events.Signal;
import clay.utils.Log.*;

import clay.render.RenderStats;
import haxe.ds.ArraySort;


@:access(clay.render.Renderer)
@:access(clay.render.LayerManager)
@:access(clay.render.DisplayObject)
class Layer {


	public var name         (default, null):String;
	public var id           (default, null):Int;
	public var active     	(get, set):Bool;

	public var objects      (default, null):Array<DisplayObject>;

	public var priority     (default, null):Int;

	public var depth_sort:Bool = true;
	public var dirty_sort:Bool = true;

	public var onprerender  (default, null):Signal<Void->Void>;
	public var onpostrender	(default, null):Signal<Void->Void>;

	public var blend_src:BlendMode;
	public var blend_dst:BlendMode;
	public var blend_eq:BlendEquation;

	#if !no_debug_console
	public var stats        (default, null):RenderStats;
	#end

	var _active:Bool;
	var _objects_toremove:Array<DisplayObject>;
	var _renderer:Renderer;
	var _manager:LayerManager;


	function new(manager:LayerManager, name:String, id:Int, priority:Int, depth_sort:Bool) {

		this.name = name;
		this.id = id;
		this.priority = priority;
		this.depth_sort = depth_sort;
		_renderer = Clay.renderer;
		_manager = manager;
		objects = [];
		_objects_toremove = [];
		_active = false;

		onprerender = new Signal();
		onpostrender = new Signal();

		blend_src = BlendMode.Undefined;
		blend_dst = BlendMode.Undefined;
		blend_eq = BlendEquation.Add;

		#if !no_debug_console
		stats = new RenderStats();
		#end
		
	}

	function destroy() {

		for (g in objects) {
			g._layer = null;
		}

		name = null;
		onprerender = null;
		onpostrender = null;
		objects = null;

	}

	public function add(geom:DisplayObject) {

		_debug('layer `$name` add geometry: ${geom.name}');

		if(geom._layer != null) {
			geom._layer._remove_unsafe(geom);
		}

		_add_unsafe(geom);

	}

	public function remove(geom:DisplayObject) {
		
		_debug('layer `$name` remove geometry: ${geom.name}');

		if(geom._layer != this) {
			log('can`t remove geometry `${geom.name}` from layer `$name`');
		} else {
			_remove_unsafe(geom);
		}

	}

	@:noCompletion public function _add_unsafe(geom:DisplayObject, _dirty_sort:Bool = true) {

		_debug('layer `$name` _add_unsafe geometry: ${geom.name}');
		
		objects.push(geom);
		geom._layer = this;

		if(_dirty_sort) {
			dirty_sort = true;
		}

	}

	@:noCompletion public function _remove_unsafe(geom:DisplayObject) {

		_debug('layer `$name` _remove_unsafe geometry: ${geom.name}');

		_objects_toremove.push(geom);
		geom._layer = null;

	}

	public function update(dt:Float) {

		for (o in objects) {
			o.update(dt);
		}
		
	}

	public function render(cam:Camera) {

		var g = Clay.renderer.target != null ? Clay.renderer.target.image.g4 : cam.buffer.image.g4;

		_verboser('layer `$name` render');

		onprerender.emit();

		remove_objects();
		sort_objects();

		#if !no_debug_console
		stats.reset();
		#end

		if(objects.length > 0) {
			var b = _renderer.renderpath;
			b.init(this, g, cam);
			b.start();
			b.render(objects);
			b.end();
		}

		#if !no_debug_console
		_renderer.stats.add(stats);
		#end

		onpostrender.emit();

	}

	inline function sort_objects() {

		if(depth_sort && dirty_sort) {
			ArraySort.sort(objects, sort_displayobjects);
			dirty_sort = false;
		}

	}

	inline function remove_objects() {
		
		if(_objects_toremove.length > 0) {
			for (o in _objects_toremove) {
				objects.remove(o);
			}
			_objects_toremove.splice(0, _objects_toremove.length);
		}

	}

    inline function sort_displayobjects(a:DisplayObject, b:DisplayObject):Int {

    	if(a.sort_key < b.sort_key) {
    		return -1;
    	} else if(a.sort_key > b.sort_key) {
    		return 1;
    	}

    	return 0;

    }

	inline function get_active():Bool {

		return _active;

	}
	
	inline function set_active(value:Bool):Bool {

		_active = value;

		if(_manager != null) {
			if(_active){
				_manager.enable(this);
			} else {
				_manager.disable(this);
			}
		}
		
		return _active;

	}


}