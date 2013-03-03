package cn.vimfung.mybooklet.framework.module.myposts.events
{
	import flash.events.Event;
	
	/**
	 * 颜色筛选事件 
	 * @author Administrator
	 * 
	 */	
	public class ColorFilterEvent extends Event
	{
		public function ColorFilterEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * 颜色变更 
		 */		
		public static const COLOR_CHANGE:String = "colorChange";
		
		private var _color:uint;

		/**
		 * 获取颜色 
		 * @return 颜色值 
		 * 
		 */		
		public function get color():uint
		{
			return _color;
		}

		/**
		 * 设置颜色值 
		 * @param value 颜色值
		 * 
		 */		
		public function set color(value:uint):void
		{
			_color = value;
		}

	}
}