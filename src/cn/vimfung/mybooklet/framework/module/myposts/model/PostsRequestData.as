package cn.vimfung.mybooklet.framework.module.myposts.model
{
	/**
	 * 文章请求数据 
	 * @author Administrator
	 * 
	 */	
	public class PostsRequestData extends Object
	{
		public function PostsRequestData()
		{
			super();
		}
		
		private var _keyword:String;
		private var _page:Number;
		private var _color:uint;

		/**
		 * 获取筛选颜色 
		 * @return 筛选颜色
		 * 
		 */		
		public function get color():uint
		{
			return _color;
		}

		/**
		 * 设置筛选颜色 
		 * @param value 筛选颜色
		 * 
		 */		
		public function set color(value:uint):void
		{
			_color = value;
		}

		/**
		 * 获取页码 
		 * @return 页码 
		 * 
		 */		
		public function get page():Number
		{
			return _page;
		}

		/**
		 * 设置页码 
		 * @param value 页码
		 * 
		 */		
		public function set page(value:Number):void
		{
			_page = value;
		}

		/**
		 * 获取关键字 
		 * @return 关键字
		 * 
		 */		
		public function get keyword():String
		{
			return _keyword;
		}

		/**
		 * 设置关键字 
		 * @param value 关键字
		 * 
		 */		
		public function set keyword(value:String):void
		{
			_keyword = value;
		}

	}
}