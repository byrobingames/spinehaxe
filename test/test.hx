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
	
	public var rootBoneX:Float;
	public var rootBoneY:Float;

	public var mode:Int = 1;
	
	public var bodyDef:B2BodyDef;
	public var md:B2MassData;
	public var bodyScale:Point;
	public var groupID:Int;
	public var ignoreGravity:Bool;
	public var isStaticBody:Bool = false;
	public var isKinematicBody:Bool = false;

	public function new
	(
		spineName:String, 
		scaleSkeleton:Float = 1.0, 
		isBodyType:Int = 0,
		actor:Actor
	) 
	{
		super(actor);
		this.spineName = spineName;
		this.scaleSkeleton = scaleSkeleton;
		this.rootBoneX = actor.getX();//rootBoneX;
		this.rootBoneY = actor.getY();//rootBoneY;
		
		this.groupID = actor.groupID;
		this.ignoreGravity = actor.ignoreGravity;
		
		if (isBodyType == 1) isStaticBody = true;
		if (isBodyType == 2) isKinematicBody = true;
		
		initSpine();
	}
	
	public function initSpine():Void
	{
	
		trace("initSpine");
		lastTime = haxe.Timer.stamp();

		atlas = new Atlas(Assets.getText("assets/data/" + spineName + ".atlas"), new BitmapDataTextureLoader("assets/data/"));
		
		//json = new SkeletonJson(new AtlasAttachmentLoader(atlas));
		json = new SkeletonJson(new B2AtlasAttachmentLoader(atlas));
		json.scale = scaleSkeleton;
		skeletonData = json.readSkeletonData(Assets.getText("assets/data/" + spineName + ".json"), spineName);
		
		Bone.yDown = true;
		
		//set Actor same width and height as SpineSkeleton
		actor.disableActorDrawing();
		//actor.cacheWidth = 1.0;// (skeletonData.width * json.scale) ;
		//actor.cacheHeight = 1.0; (skeletonData.height * json.scale);
		//actor.setOriginPoint(Std.int(actor.getXCenter() - (actor.cacheWidth / 2)), Std.int(actor.getYCenter() - (actor.cacheHeight /2)));

		// Define mixing between animations.
		stateData = new AnimationStateData(skeletonData);
		state = new AnimationState(stateData);
		
		renderer = new SkeletonAnimation(skeletonData, stateData);
		skeleton = renderer.skeleton;
		skeleton.updateCache();
		skeleton.flipX = false;
		skeleton.flipY = false;
		
		skeleton.x = rootBoneX;
		skeleton.y = rootBoneY;
		
		skeleton.updateWorldTransform();
		var drawOrder:Array<Slot> = skeleton.drawOrder;
		for (slot in drawOrder)
		{
			if (slot.attachment == null)
			{
				continue;
			}
			
			if (Std.is(slot.attachment, MeshAttachment))
			{
				renderer.renderMeshes = true;
				break;
			}
		}
		
		
		state = renderer.state;
		
		state.onStart.add(function (trackEntry) {
			trace(trackEntry.trackIndex + " fuu start");
		});
		state.onEnd.add(function (trackEntry) {
			trace(trackEntry.trackIndex + " end");
		});
		state.onComplete.add(function (trackEntry) {
			trace(trackEntry.trackIndex + " complete");
		});
		state.onEvent.add(function (trackEntry, event) {
			trace(trackEntry.trackIndex + " event: " + event.data + ": " + event.intValue + ", " + event.floatValue + ", " + event.stringValue);
		});
		
		skeleton.setSlotsToSetupPose();
		skeleton.setBonesToSetupPose();
		
		
		
		initSpineBody();
		
		
		//actor.addChild(renderer);
		Lib.current.addChild(renderer);
		
		Lib.current.addEventListener(Event.ENTER_FRAME, render);
		//Lib.current.addEventListener(Event.RENDER, render);	
		 
	}
	
	public function initSpineBody():Void
	{	
		
		for (slot in skeleton.drawOrder)
		{
			if (slot.attachment == null) continue;
			
			if (!Std.is(slot.attachment, B2RegionAttachment)) continue;
			var regionAttachment:B2RegionAttachment = cast slot.attachment;
			
			slot.
					
			if (regionAttachment != null)
			{
				var region:AtlasRegion = cast regionAttachment.rendererObject;
				var bone:Bone = slot.bone;
				
				trace("regionAttachment name " + regionAttachment.name);
				trace("regionAttachment width " + regionAttachment.regionWidth);
				trace("region width " + region.width);
				trace("regionAttachment x" + regionAttachment.x);
				trace("regionAttachment scalex " + regionAttachment.scaleX);
				trace("region x " + region.x);
				trace("boneworldx " + bone.worldX);
				trace("skeletonx " + skeleton.x);
				
				//if (regionAttachment.name == "head"){
				//var x = Engine.toPhysicalUnits(actor.getX());// + slot.bone.worldX + rootBoneX);
				//var y = Engine.toPhysicalUnits(actor.getY());// slot.bone.worldY + rootBoneY);
			
					
					//var boxPoly:B2PolygonShape = new B2PolygonShape();
					var hx = regionAttachment.width / 2 * regionAttachment.scaleX;
					var hy = regionAttachment.height / 2 * regionAttachment.scaleY;
					//boxPoly.setAsBox(hx, hy);
					//boxPoly.setAsOrientedBox(hx,hy,new B2Vec2(x,y),0);
					
					var x = skeleton.x - bone.worldX;
					var y = skeleton.y - bone.worldY;
					actor.addRectangularShape(x,y,hx,hy);
					/*actor.bodyDef = new B2BodyDef();
					actor.bodyDef.position.x = x;
					actor.bodyDef.position.y = y;
					//bodyDef.angle = -regionAttachment.rotation;
					if (isStaticBody){
						actor.bodyDef.type = B2Body.b2_staticBody;
					}else if (isKinematicBody){
						actor.bodyDef.type = B2Body.b2_kinematicBody;
					}else{
						actor.bodyDef.type = B2Body.b2_dynamicBody;
					}
					
					actor.bodyDef.groupID = this.groupID;
					//bodyDef.bullet = true;
					actor.bodyDef.allowSleep = false;
					actor.bodyDef.userData = actor;// regionAttachment.name;
					actor.bodyDef.ignoreGravity = this.ignoreGravity;
					actor.body = Engine.engine.world.createBody(actor.bodyDef);
					//regionAttachment.body.createFixture2(boxPoly);
					
					var fixtureDef = new B2FixtureDef();
					fixtureDef.groupID = groupID;
					fixtureDef.density = 0.1;
					fixtureDef.shape = boxPoly;
					fixtureDef.friction = 1.0;
					fixtureDef.isSensor = false;
					fixtureDef.restitution = 0;
					fixtureDef.userData = actor;// regionAttachment.name;
					actor.body.createFixture(fixtureDef);*/
					
					skeleton.updateWorldTransform();
					skeleton.setToSetupPose();

					//boxPoly = null;
					
					
					//actor.addRectangularShape(bone.worldX + getWidth() + rootBoneX,bone.worldY + getHeight() + rootBoneY ,regionAttachment.regionWidth * scaleSkeleton,regionAttachment.regionHeight * scaleSkeleton);
					/*bodyDef = new B2BodyDef();
					bodyDef.position.x = Engine.toPhysicalUnits(getX() + bone.worldX);// getX() - (getWidth() / 2)); // + bone.parent.x);// + );// - ;
					bodyDef.position.y = Engine.toPhysicalUnits(getY() + bone.worldY);//getY() - (getHeight() / 2));// getY() -  + ;// - getY());  //+ bone.parent.y);// - bone.worldY);// + );// -(getHeight() - (atlasRegion.height * scaleSkeleton)));// (bone.worldY - getY());// - ;
					//bodyDef.angle = bone.rotation;
					//bodyDef.position.set()
					bodyDef.groupID = actor.groupID;
					bodyDef.type = B2Body.b2_staticBody;
					bodyDef.allowSleep = false;
					bodyDef.userData = attachmentName_;
					atlasRegion.body = Engine.engine.world.createBody(bodyDef);*/
					
				//}	
			}
			
		}
		
		//actor.addChild(renderer);
		//Lib.current.addChild(renderer);
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
		return skeletonData.width * json.scale;
	}
	
	public function getHeight():Float
	{
		return skeletonData.height * json.scale;
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
		
		skeleton.x = actor.getX();
		skeleton.y = actor.getY();
		//actor.realX = actor.realX + skeleton.x- actor.currOffset.x;
		//actor.realY = actor.realY + skeleton.y - actor.currOffset.y;
		
		/*for (slot in skeleton.drawOrder) {
			if (!Std.is(slot.attachment, B2RegionAttachment)) continue;
			var attachment:B2RegionAttachment = cast slot.attachment;
			if (attachment.body == null) continue;
			var x = Engine.toPhysicalUnits(actor.getX() + slot.bone.worldX);
			var y = Engine.toPhysicalUnits(actor.getY() + slot.bone.worldY);
			actor.body.setPositionAndAngle(new B2Vec2(x, y), 0);
		}*/
	}
	
	public function destroySelf():Void
	{
		Lib.current.removeEventListener(Event.ENTER_FRAME, render);
		//Lib.current.removeEventListener(Event.RENDER, render);
		
		if(renderer != null)
			renderer.destroy();
			
		if (bodyDef != null){
			bodyDef.userData = null;
			bodyDef = null;
		}
		
		renderer = null;
		skeletonData = null;
		skeleton = null;
		state = null;
		stateData = null;
		
		recycleActor(actor);
		
	}

}

class B2AtlasAttachmentLoader extends AtlasAttachmentLoader
{
	
	public function new(atlas:Atlas){
		super(atlas);
	}
	
	override
	public function newRegionAttachment(skin:Skin, name:String, path:String):RegionAttachment {
		var region:AtlasRegion = atlas.findRegion(path);
		if (region == null)
			throw "Region not found in atlas: " + path + " (region attachment: " + name + ")";
		var attachment:B2RegionAttachment = new B2RegionAttachment(name);
		attachment.rendererObject = region;
		var scaleX:Float = region.page.width / nextPOT(region.page.width);
		var scaleY:Float = region.page.height / nextPOT(region.page.height);
		attachment.setUVs(region.u * scaleX, region.v * scaleY, region.u2 * scaleX, region.v2 * scaleY, region.rotate);
		attachment.regionOffsetX = region.offsetX;
		attachment.regionOffsetY = region.offsetY;
		attachment.regionWidth = region.width;
		attachment.regionHeight = region.height;
		attachment.regionOriginalWidth = region.originalWidth;
		attachment.regionOriginalHeight = region.originalHeight;
		return attachment;
	}
	
	static public function nextPOT(value:Int):Int {
		value--;
		value |= value >> 1;
		value |= value >> 2;
		value |= value >> 4;
		value |= value >> 8;
		value |= value >> 16;
		return value + 1;
	}
}

class B2RegionAttachment extends RegionAttachment
{
	public var body:B2Body;
	
	public function new (name:String ){
		super(name);
	}
	
}