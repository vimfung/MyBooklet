package cn.vimfung.mybooklet.framework.events
{
	import flash.events.Event;
	
	/**
	 * 补丁事件 
	 * @author Administrator
	 * 
	 */	
	public class PatchEvent extends Event
	{
		public function PatchEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * 补丁成功 
		 */		
		public static const PATCH_SUCCESS:String = "patchSuccess";
		
		/**
		 * 补丁失败 
		 */		
		public static const PATCH_FAIL:String = "patchFail";
		
		private var _name:String;
		private var _error:Error;

		/**
		 * 获取补丁名称 
		 * @return 名称
		 * 
		 */		
		public function get name():String
		{
			return _name;
		}

		/**
		 * 设置补丁名称 
		 * @param value 名称
		 * 
		 */		
		public function set name(value:String):void
		{
			_name = value;
		}

		/**
		 * 获取错误信息 
		 * @return 错误信息
		 * 
		 */		
		public function get error():Error
		{
			return _error;
		}

		/**
		 * 设置错误信息 
		 * @param value 错误信息
		 * 
		 */		
		public function set error(value:Error):void
		{
			_error = value;
		}

	}
}