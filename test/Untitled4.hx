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
import com.stencyl.Engine;
import com.stencyl.behavior.ActorScript;
import com.stencyl.behavior.Script;
import com.stencyl.behavior.Script.*;
import com.stencyl.models.Actor;
import com.stencyl.graphics.G;
import openfl.geom.Point;

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
	
	var vertices:Array<B2Vec2>;
	
	public var box:B2PolygonShape;
	public var body:B2Body;
	public var bodyDef:B2BodyDef;
	public var md:B2MassData;
	//public var bodyScale:Point;

	public function new(spineName:String, scaleSkeleton:Float = 1.0, actor:Actor) 
	{
		super(actor);
		this.spineName = spineName;
		this.scaleSkeleton = scaleSkeleton;
		
		initSpine();
	}
	
	public function initSpine():Void
	{
	
		trace("initSpine");
		lastTime = haxe.Timer.stamp();

		atlas = new Atlas(Assets.getText("assets/data/" + spineName + ".atlas"), new BitmapDataTextureLoader("assets/data/"));
		
		json = new SkeletonJson(new AtlasAttachmentLoader(atlas));
		json.scale = scaleSkeleton;
		skeletonData = json.readSkeletonData(Assets.getText("assets/data/" + spineName + ".json"), spineName);
		
		//set Actor same width and height as SpineSkeleton
		this.actor.disableActorDrawing();
		this.actor.cacheWidth = (skeletonData.width * json.scale) ;
		this.actor.cacheHeight = (skeletonData.height * json.scale);

		// Define mixing between animations.
		stateData = new AnimationStateData(skeletonData);
		
		renderer = new SkeletonAnimation(skeletonData, stateData);
		
		skeleton = renderer.skeleton;
		skeleton.updateCache();
		skeleton.flipX = false;
		skeleton.flipY = false;
		skeleton.x = getRootboneX//actor.getX() + getRootBoneX(); //;
		skeleton.y = getRootBoneY;//actor.getY() + getRootBoneY(); //- (actor.cacheHeight / 2);
		#if mesh
		renderer.renderMeshes = true;
		#end
		
		skeleton.updateWorldTransform();
		
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
		
		this.actor.addChild(renderer);
		//Lib.current.addChild(renderer);

		Lib.current.addEventListener(Event.ENTER_FRAME, render);
		//Lib.current.addEventListener(Event.RENDER, render);
		
		//createB2PolyBox();
	}
	
	private function initBody(){
		
		/*var box = new B2PolygonShape();
		box.setAsBox(1, 1);
		body.createFixture2(box, 0.1);
			
		md = new B2MassData();
		md.mass = bodyDef.mass;
		md.I = bodyDef.aMass;
		md.center.x = 0;
		md.center.y = 0;
			
		body.setMassData(md);*/
			
		
	}
	
	public function createB2PolyBox(){
		vertices = new Array<B2Vec2>();
		
		//add box2d to regions
		for (slot in skeleton.slots){
		
			if (slot == null) continue;
			var bone:Bone = slot.bone;
			if (bone == null) continue;
			try 
			{
				
				skeleton.setAttachment(slot.data.name, slot.data.attachmentName);
		
				trace("parentBoneX: " + bone.parent.x);
				trace("parentBoneY" + bone.parent.y);
				trace("BoneX " + bone.x);
				trace("BoneY " + bone.y);
				var attachmentName_ = slot.attachment.name;
				trace("AttachmentName: " + attachmentName_ );
			
				var atlasRegion:B2AtlasRegion = new B2AtlasRegion(atlas.findRegion(attachmentName_));
	
				trace("Height: " + atlasRegion.region.height * scaleSkeleton);
				trace("Width" + atlasRegion.region.width * scaleSkeleton);
				trace("X" + atlasRegion.region.x * scaleSkeleton);
				trace("y" + atlasRegion.region.y * scaleSkeleton);
				trace("offsetx" + atlasRegion.region.offsetX * scaleSkeleton);
				trace("offsety" + atlasRegion.region.offsetY * scaleSkeleton);
				trace("BoneWorldX" + bone.parent.worldX);
				trace("BoneWorldY" + bone.parent.worldY);
				
				trace("BoneY" + bone.y);
				trace("BoneWorldScaleX" + bone.worldScaleX);
				trace("BoneWorldScaleY" + bone.worldScaleY);
				trace("SkeletonX" + getX());
				trace("SkeletonY" + getY());
				trace("bonelength" + bone.data.length);
				trace("rotaionworld x " + bone.worldRotationX);
				trace("rotaionworld y " + bone.worldRotationY);
				
				if (attachmentName_ == "head"){
					
					
					bodyDef = new B2BodyDef();
					bodyDef.position.x = Engine.toPhysicalUnits(getX() + bone.worldX);// getX() - (getWidth() / 2)); // + bone.parent.x);// + );// - ;
					bodyDef.position.y = Engine.toPhysicalUnits(getY() + bone.worldY);//getY() - (getHeight() / 2));// getY() -  + ;// - getY());  //+ bone.parent.y);// - bone.worldY);// + );// -(getHeight() - (atlasRegion.height * scaleSkeleton)));// (bone.worldY - getY());// - ;
					//bodyDef.angle = bone.rotation;
					//bodyDef.position.set()
					bodyDef.groupID = actor.groupID;
					bodyDef.type = B2Body.b2_staticBody;
					bodyDef.allowSleep = false;
					bodyDef.userData = attachmentName_;
					atlasRegion.body = Engine.engine.world.createBody(bodyDef);
					
					trace("1");
					var polyBox:B2PolygonShape = new B2PolygonShape();
					//
							
					var w = atlasRegion.region.width * scaleSkeleton;
					var h = atlasRegion.region.height * scaleSkeleton;
					var x = bone.worldX; //- (getX() + bone.x);// - (getX() / 2);// + bone.x;//getX(); //atlasRegion.x ;
					var y = bone.worldY; //- (getY() + bone.y);// - (getHeight() / 2);// + bone.y;//getX();//atlasRegion.y ;
					x = Engine.toPhysicalUnits(x - Math.floor(getWidth() / 2));
					y = Engine.toPhysicalUnits(y - Math.floor(getHeight() / 2));
					w = Engine.toPhysicalUnits(w / 2);
					h = Engine.toPhysicalUnits(h / 2);
					//vertices.push(new B2Vec2(x, y));
					//vertices.push(new B2Vec2(x + w, y));
					//vertices.push(new B2Vec2(x + w, y + h));
					//vertices.push(new B2Vec2(x, y + h));
					//trace("2");
					//polyBox.setAsVector(vertices);*/
					
					//polyBox.setAsBox(w / 2, h / 2); //Engine.toPhysicalUnits(w / 2), Engine.toPhysicalUnits(h / 2));
					polyBox.setAsOrientedBox(w,h,new B2Vec2(x,y),0);
					
					//var fixtureDef:B2FixtureDef = new B2FixtureDef();
					//fixtureDef.shape = polyBox;
					//fixtureDef.isSensor = false;
					//fixtureDef.userData = attachmentName_;
					//actor.body.createFixture(fixtureDef);
					
					var fixture:B2Fixture = atlasRegion.body.createFixture2(polyBox, 1);
					fixture.SetUserData(attachmentName_);
					
					//polyBox = null;
					
					//actor.addRectangularShape(x, y ,w , h);
					
					skeleton.updateWorldTransform();
					
				}
				
			}catch (err:Dynamic)
			{
				trace("Error: " + err);
			}
			
		}
		
		
	}
	
	public function getRootBoneX():Float
	{
		return rootBoneX;
	}
	
	public function setRootBoneX(rootBoneX:Float):Void
	{
		
		this.rootBoneX = rootBoneX;
	}
	
	public function getRootBoneY():Float
	{
		return rootBoneY;
	}
	
	
	public function setRootBoneY(rootBoneY:Float):Void
	{
		this.rootBoneY = rootBoneY;
	}
	
	
	public function getX():Float
	{
		return skeleton.x;
	}
	
	public function getY():Float
	{
		return skeleton.y;
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
		
		//skeleton.x = actor.getX() + getRootBoneX();
		//skeleton.y = actor.getY() + getRootBoneY();
		
		for (slot in skeleton.slots){
			
			if (slot == null) continue;
			
			var bone:Bone = slot.bone;
			if (bone == null) continue;
			
			try 
			{
				
				//skeleton.setAttachment(slot.data.name, slot.data.attachmentName);
				//trace("parentBone: " + bone.parent.x);
				//trace("BoneX" + bone.x);
				
				//var attachmentName_ = slot.attachment.name;
				//trace("AttachmentName: " + attachmentName_ );
				//trace("bone scalex" + bone.worldScaleX);
				
				
				//var atlasRegion:AtlasRegion = atlas.findRegion(attachmentName_);
				//trace("Body: " + atlasRegion.body.getUserData());
				//if (attachmentName_ == "head"){
					
					//atlasRegion.body.setPosition = Engine.toPhysicalUnits(bone.worldX +  bone.x);// + (atlasRegion.width * scaleSkeleton / 2));// - ;
					
					
						
				//}
				
			}catch (err:Dynamic)
			{
				trace("Error: " + err);
			}
			
		}
		
		
	}
	
	public function destroySelf():Void
	{
		Lib.current.removeEventListener(Event.ENTER_FRAME, render);
		//Lib.current.removeEventListener(Event.RENDER, render);
		
		if(renderer != null)
			renderer.destroy();
		
		renderer = null;
		skeletonData = null;
		skeleton = null;
		state = null;
		stateData = null;
		
		recycleActor(actor);
		
	}

}

class B2AtlasRegion
{
	public var body:B2Body;
	public var region:AtlasRegion;
	
	public function new(region:AtlasRegion)
	{
		this.region = region;
	}
}
