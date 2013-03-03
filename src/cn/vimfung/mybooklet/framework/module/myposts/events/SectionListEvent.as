package cn.vimfung.mybooklet.framework.module.myposts.events
{
	import cn.vimfung.mybooklet.framework.module.myposts.model.SectionListIndexPath;
	
	import flash.events.Event;
	
	/**
	 * SectionList事件 
	 * @author Administrator
	 * 
	 */	
	public class SectionListEvent extends Event
	{
		public function SectionListEvent(type:String, bubbles:Boolean=false, cancelable:Boolean=false)
		{
			super(type, bubbles, cancelable);
		}
		
		/**
		 * 列表项将要显示 
		 */		
		public static const ITEM_WILL_DISPLAY:String = "itemWillDisplay";
		
		/**
		 * 列表项点击 
		 */		
		public static const ITEM_CLICK:String = "itemClick";
		
		/**
		 * 小节将要显示 
		 */		
		public static const SECTION_WILL_DISPLAY:String = "sectionWillDisplay";
		
		private var _indexPath:SectionListIndexPath;
		private var _data:Object;
		private var _section:int;

		/**
		 * 获取小节索引 
		 * @return 小节索引
		 * 
		 */		
		public function get section():int
		{
			return _section;
		}

		/**
		 * 设置小节索引 
		 * @param value 小节索引
		 * 
		 */		
		public function set section(value:int):void
		{
			_section = value;
		}

		/**
		 * 获取数据 
		 * @return 数据
		 * 
		 */		
		public function get data():Object
		{
			return _data;
		}

		/**
		 * 设置数据 
		 * @param value 数据
		 * 
		 */		
		public function set data(value:Object):void
		{
			_data = value;
		}

		/**
		 * 获取索引位置 
		 * @return 索引位置
		 * 
		 */		
		public function get indexPath():SectionListIndexPath
		{
			return _indexPath;
		}

		/**
		 * 设置索引位置 
		 * @param value 索引位置
		 * 
		 */		
		public function set indexPath(value:SectionListIndexPath):void
		{
			_indexPath = value;
		}

	}
}