/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.1
 *
 * Copyright (c) 2013, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to install, execute and perform the Spine Runtimes
 * Software (the "Software") solely for internal use. Without the written
 * permission of Esoteric Software (typically granted by licensing Spine), you
 * may not (a) modify, translate, adapt or otherwise create derivative works,
 * improvements of the Software or develop new applications using the Software
 * or (b) remove, delete, alter or obscure any trademarks or any copyright,
 * trademark, patent or other intellectual property or proprietary rights
 * notices on or in the Software, including any copy thereof. Redistributions
 * in binary or source form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/
package spinehaxe.animation;
import spinehaxe.Exception;
using Lambda;

class BaseListeners<F> {
	@:allow(spinehaxe.animation)
	var _listeners:Array<F> = new Array();

	public function new() {}

	public function add(listener:F):Void {
		if (listener == null)
			throw new IllegalArgumentException("listener cannot be null.");
		var indexOf:Int = _listeners.indexOf(listener);
		if (indexOf == -1)
			_listeners.push(listener);
	}

	public function remove(listener:F):Void {
		if (listener == null)
			throw new IllegalArgumentException("listener cannot be null.");
		var indexOf:Int = _listeners.indexOf(listener);
		if (indexOf != -1)
			_listeners.splice(indexOf, 1);
	}
}

class Listeners extends BaseListeners<TrackEntry->Void>
{
	public function invoke(entry:TrackEntry) {
		for (listener in _listeners)
			listener(entry);
	}
}

class EventListeners extends BaseListeners<TrackEntry->Event->Void>
{
	public function invoke(entry:TrackEntry, event:Event) {
		for (listener in _listeners)
			listener(entry, event);
	}
}
