package cn.vimfung.mybooklet.framework.model
{
	/**
	 * 进度信息 
	 * @author Administrator
	 * 
	 */	
	public class ProgressInfo extends Object
	{
		public function ProgressInfo()
		{
			super();
		}
		
		private var _progress:Number;
		private var _total:Number;

		/**
		 * 获取总进度 
		 * @return 总进度
		 * 
		 */		
		public function get total():Number
		{
			return _total;
		}

		/**
		 * 设置总进度 
		 * @param value 总进度
		 * 
		 */		
		public function set total(value:Number):void
		{
			_total = value;
		}

		/**
		 * 获取当前进度 
		 * @return 当前进度
		 * 
		 */		
		public function get progress():Number
		{
			return _progress;
		}

		/**
		 * 设置当前进度 
		 * @param value 当前进度
		 * 
		 */		
		public function set progress(value:Number):void
		{
			_progress = value;
		}

	}
}