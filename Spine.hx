package;

/**
 * ...
 * @author robinschaafsma
 * www.byrobin.nl
 */

import spinehaxe.Exception;
import spinehaxe.SkeletonBounds;
import spinehaxe.Skin;
import spinehaxe.attachments.AtlasAttachmentLoader;
import spinehaxe.attachments.AttachmentLoader;
import spinehaxe.attachments.Attachment;
import spinehaxe.attachments.BoundingBoxAttachment;
import spinehaxe.attachments.MeshAttachment;
import spinehaxe.attachments.RegionAttachment;
import spinehaxe.Bone;
import spinehaxe.Skeleton;
import spinehaxe.SkeletonData;
import spinehaxe.SkeletonJson;
import spinehaxe.animation.AnimationState;
import spinehaxe.animation.AnimationStateData;
import spinehaxe.atlas.Atlas;
import spinehaxe.atlas.AtlasRegion;
import spinehaxe.platform.openfl.BitmapDataTextureLoader;
import spinehaxe.platform.openfl.SkeletonAnimation;
import spinehaxe.Slot;
import spinehaxe.MathUtils;
//import spinehaxe.Event;

import openfl.display.Sprite;
import openfl.Assets;
import openfl.Lib;
import openfl.events.Event;
import openfl.geom.Point;
import openfl.geom.Vector3D;
import openfl.geom.Matrix;

import com.stencyl.Engine;
import com.stencyl.behavior.ActorScript;
import com.stencyl.behavior.Script;
import com.stencyl.behavior.Script.*;
import com.stencyl.models.Actor;
import com.stencyl.models.GameModel;
import com.stencyl.graphics.G;

//import box2D
import box2D.dynamics.B2Body;
import box2D.dynamics.B2BodyDef;
import box2D.dynamics.B2Fixture;
import box2D.dynamics.B2FixtureDef;
import box2D.dynamics.B2World;
import box2D.collision.shapes.B2Shape;
import box2D.collision.shapes.B2PolygonShape;
import box2D.collision.shapes.B2CircleShape;
import box2D.collision.shapes.B2EdgeShape;
import box2D.collision.shapes.B2MassData;
import box2D.dynamics.contacts.B2Contact;
import box2D.dynamics.contacts.B2ContactEdge;
import box2D.common.math.B2Vec2;
import box2D.common.math.B2Transform;
import box2D.collision.B2WorldManifold;

class Spine extends ActorScript
{	
	private var engine:Engine;
	public var renderer:SkeletonAnimation;
	
	public var atlasLoader:AtlasAttachmentLoader;

	public var atlas:Atlas;
	public var skeleton:Skeleton;
	public var skeletonData:SkeletonData;
	public var skeletonBounds:SkeletonBounds;
	public var state:AnimationState;
	public var stateData:AnimationStateData;
	public var json:SkeletonJson;
	public var slot:Slot;
	
	public var lastTime:Float = 0.0;
	
	public var spineName:String;
	public var scaleSkeleton:Float;
	 
	public var rootBoneX:Float = 0.0;
	public var rootBoneY:Float = 0.0;

	public var mode:Int = 1;

	public function new
	(
		spineName:String, 
		scaleSkeleton:Float = 1.0,
		actor:Actor
	) 
	{
		super(actor);
		this.spineName = spineName;
		this.scaleSkeleton = scaleSkeleton;
		
		initSpine();
	}
	
	public function initSpine():Void
	{
	
		//trace("initSpine");
		lastTime = haxe.Timer.stamp();

		atlas = new Atlas(Assets.getText("assets/data/" + spineName + "/" + spineName + ".atlas"), new BitmapDataTextureLoader("assets/data/"+ spineName + "/"));
		
		json = new SkeletonJson(new AtlasAttachmentLoader(atlas));
		json.scale = scaleSkeleton;
		skeletonData = json.readSkeletonData(Assets.getText("assets/data/" + spineName + "/" + spineName + ".json"), spineName);
		
		//set Actor width and height same as SpineSkeleton
		actor.disableActorDrawing();
		actor.cacheWidth = (skeletonData.width * json.scale) / Engine.SCALE;
		actor.cacheHeight = (skeletonData.height * json.scale) / Engine.SCALE;
		
		// Define mixing between animations.
		stateData = new AnimationStateData(skeletonData);
		state = new AnimationState(stateData);
		
		renderer = new SkeletonAnimation(skeletonData, stateData, false);
		renderer.renderMeshes = false;
		
		skeleton = renderer.skeleton;
		skeleton.updateCache();
		skeleton.flipX = false;
		skeleton.flipY = false;
		
		skeleton.x = rootBoneX;
		skeleton.y = rootBoneY;
		
		skeleton.updateWorldTransform();
			
		state = renderer.state;
		
		
		skeleton.setSlotsToSetupPose();
		skeleton.setBonesToSetupPose();
		
		
		actor.addChild(renderer);
		
		Lib.current.addEventListener(Event.ENTER_FRAME, render);
	}

	public function setX(x:Float):Void
	{
		skeleton.x = x;
		this.rootBoneX = x;
	}
	
	public function getX():Float
	{
		return rootBoneX;
	}
	
	public function setY(y:Float):Void
	{
		skeleton.y = y;
		this.rootBoneY = y;
	}
	
	public function getY():Float
	{
		return rootBoneY;
	}
	
	public function getWidth():Float
	{
		return (skeletonData.width * json.scale) / Engine.SCALE;
	}
	
	public function getHeight():Float
	{
		return (skeletonData.height * json.scale) / Engine.SCALE;
	}
	
	public function render(e:Event):Void 
	{	
		var t = haxe.Timer.stamp(),
			delta = (t - lastTime) / 3;
		lastTime = t;
		state.update(delta);
		state.apply(skeleton);
		skeleton.updateWorldTransform();
		renderer.visible = true;
	}
	
	//not necessary, if actor is killed, spine will also killed
	public function destroySelf():Void
	{
		
		Lib.current.removeEventListener(Event.ENTER_FRAME, render);
		
		if(renderer != null)
			renderer.destroy();
		
		renderer = null;
		skeletonData = null;
		skeleton = null;
		state = null;
		stateData = null;
	}
	
	//Still testing to get box2d on Spine sprites
	/*public function addRectShape(x:Float, y:Float, w:Float, h:Float, isSensor:Bool)
	{
		if (actor.physicsMode == 0)
		{
			var polygon:B2PolygonShape = new B2PolygonShape();
			var vertices:Array<B2Vec2> = new Array<B2Vec2>();
			x = Engine.toPhysicalUnits(x - Math.floor(actor.cacheWidth / 2) - actor.currOffset.x);
			y = Engine.toPhysicalUnits(y - Math.floor(actor.cacheHeight / 2) - actor.currOffset.y);
			w = Engine.toPhysicalUnits(w);
			h = Engine.toPhysicalUnits(h);
			vertices.push(new B2Vec2(x, y));
			vertices.push(new B2Vec2(x + w, y));
			vertices.push(new B2Vec2(x + w, y + h));
			vertices.push(new B2Vec2(x, y + h));
			polygon.setAsVector(vertices);
			var fixture:B2Fixture = actor.getBody().createFixture2(polygon, 1);
			fixture.groupID = actor.getGroupID();
			fixture.m_isSensor = isSensor;
			fixture.SetUserData(actor);
		}
	}*/
}