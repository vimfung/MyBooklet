package cn.vimfung.mybooklet.framework.module.myposts.model
{
	/**
	 * Section List索引 
	 * @author Administrator
	 * 
	 */	
	public class SectionListIndexPath extends Object
	{
		public function SectionListIndexPath()
		{
			super();
		}
		
		private var _row:int;
		private var _section:int;

		/**
		 * 获取分节索引
		 * @return 分节索引
		 * 
		 */		
		public function get section():int
		{
			return _section;
		}

		/**
		 * 设置分节索引 
		 * @param value 分节索引
		 * 
		 */		
		public function set section(value:int):void
		{
			_section = value;
		}

		/**
		 * 获取行索引 
		 * @return 行索引
		 * 
		 */		
		public function get row():int
		{
			return _row;
		}

		/**
		 * 设置行索引
		 * @param value 行索引
		 * 
		 */		
		public function set row(value:int):void
		{
			_row = value;
		}

	}
}