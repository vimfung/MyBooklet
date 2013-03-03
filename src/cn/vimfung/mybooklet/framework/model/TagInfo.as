package cn.vimfung.mybooklet.framework.model
{
	/**
	 * 标签信息 
	 * @author Administrator
	 * 
	 */	
	public class TagInfo extends Object
	{
		public function TagInfo()
		{
			super();
		}
		
		private var _name:String;
		private var _useCount:int;
		private var _createTime:Date;
		private var _latestTime:Date;

		/**
		 * 获取最近使用时间 
		 * @return 最近使用时间
		 * 
		 */		
		public function get latestTime():Date
		{
			return _latestTime;
		}

		/**
		 * 设置最近使用时间 
		 * @param value 最近使用时间
		 * 
		 */		
		public function set latestTime(value:Date):void
		{
			_latestTime = value;
		}

		/**
		 * 获取创建时间 
		 * @return 创建时间
		 * 
		 */		
		public function get createTime():Date
		{
			return _createTime;
		}

		/**
		 * 设置创建时间 
		 * @param value 创建时间
		 * 
		 */		
		public function set createTime(value:Date):void
		{
			_createTime = value;
		}

		/**
		 * 获取使用次数 
		 * @return 使用次数
		 * 
		 */		
		public function get useCount():int
		{
			return _useCount;
		}

		/**
		 * 设置使用次数 
		 * @param value 使用次数
		 * 
		 */		
		public function set useCount(value:int):void
		{
			_useCount = value;
		}

		/**
		 * 获取标签名称 
		 * @return 标签名称
		 * 
		 */		
		public function get name():String
		{
			return _name;
		}
		
		/**
		 * 设置标签名称 
		 * @param value 标签名称
		 * 
		 */		
		public function set name(value:String):void
		{
			_name = value;
		}

	}
}