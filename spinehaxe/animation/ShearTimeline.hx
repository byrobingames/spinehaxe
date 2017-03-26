/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spinehaxe.animation;

import spinehaxe.Event;
import spinehaxe.Skeleton;
import spinehaxe.Bone;

class ShearTimeline extends TranslateTimeline {
	static public inline var ENTRIES:Int = TranslateTimeline.ENTRIES;
	static inline var PREV_TIME:Int = TranslateTimeline.PREV_TIME;
	static inline var PREV_X:Int = TranslateTimeline.PREV_X;
	static inline var PREV_Y:Int = TranslateTimeline.PREV_Y;
	static inline var X:Int = TranslateTimeline.X;
	static inline var Y:Int = TranslateTimeline.Y;

	public function new(frameCount:Int) {
		super(frameCount);
	}

	override public function getPropertyId():Int {
		return (TimelineType.shear << 24) + boneIndex;
	}

	override public function apply(skeleton:Skeleton, lastTime:Float, time:Float, firedEvents:Array<Event>, alpha:Float, setupPose:Bool, mixingOut:Bool):Void {
		var bone:Bone = skeleton.bones[boneIndex];

		if (time < frames[0]) {
			if (setupPose) {
				bone.shearX = bone.data.shearX;
				bone.shearY = bone.data.shearY;
			}
			return;
		}

		var x:Float, y:Float;
		if (time >= frames[frames.length - ENTRIES]) { // Time is after last frame.
			x = frames[frames.length + PREV_X];
			y = frames[frames.length + PREV_Y];
		} else {
			// Interpolate between the previous frame and the current frame.
			var frame:Int = Animation.binarySearch(frames, time, ENTRIES);
			x = frames[frame + PREV_X];
			y = frames[frame + PREV_Y];
			var frameTime:Float = frames[frame];
			var percent:Float = getCurvePercent(Std.int(frame / ENTRIES - 1),
				1 - (time - frameTime) / (frames[frame + PREV_TIME] - frameTime));

			x = x + (frames[frame + X] - x) * percent;
			y = y + (frames[frame + Y] - y) * percent;
		}
		if (setupPose) {
			bone.shearX = bone.data.shearX + x * alpha;
			bone.shearY = bone.data.shearY + y * alpha;
		} else {
			bone.shearX += (bone.data.shearX + x - bone.shearX) * alpha;
			bone.shearY += (bone.data.shearY + y - bone.shearY) * alpha;
		}
	}
}
