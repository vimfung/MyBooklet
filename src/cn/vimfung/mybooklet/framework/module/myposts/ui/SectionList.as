package cn.vimfung.mybooklet.framework.module.myposts.ui
{
	import cn.vimfung.mybooklet.framework.module.myposts.model.SectionListDataProvider;
	import cn.vimfung.mybooklet.framework.module.myposts.model.SectionListIndexPath;
	
	import flash.utils.Dictionary;
	
	import spark.components.Group;
	import spark.components.Scroller;
	import spark.core.IViewport;
	
	/**
	 * 项目将要显示 
	 */	
	[Event(name="itemWillDisplay", type="cn.vimfung.mybooklet.framework.module.myposts.events.SectionListEvent")]
	
	/**
	 * 项目小节将要显示 
	 */	
	[Event(name="sectionWillDisplay", type="cn.vimfung.mybooklet.framework.module.myposts.events.SectionListEvent")]
	
	/**
	 * 项目点击 
	 */	
	[Event(name="itemClick", type="cn.vimfung.mybooklet.framework.module.myposts.events.SectionListEvent")]
	
	/**
	 * 分节列表 
	 * @author Administrator
	 * 
	 */	
	public class SectionList extends Scroller
	{
		public function SectionList()
		{
			super();
			
			_contentView = new SectionListContentView();
			_contentView.percentWidth = 100;
			_contentView.percentHeight = 100;
			this.viewport = _contentView;
		}
		
		private var _contentView:SectionListContentView;
		
		/**
		 * 获取数据源 
		 * @return 数据源
		 * 
		 */		
		public function get dataProvider():SectionListDataProvider
		{
			return _contentView.dataProvider;
		}

		/**
		 * 设置数据源 
		 * @param value 数据源
		 * 
		 */		
		public function set dataProvider(value:SectionListDataProvider):void
		{
			_contentView.dataProvider = value;
		}
		
		/**
		 * 获取选中项目 
		 * @return 选中项目
		 * 
		 */		
		public function get selectedItem():*
		{
			return _contentView.selectedItem;
		}
		
		/**
		 * 设置选中项目 
		 * @param value 选中项目
		 * 
		 */		
		public function set selectedItem(value:*):void
		{
			_contentView.selectedItem = value;
		}
		
		/**
		 * 获取选中索引 
		 * @return 选中索引
		 * 
		 */		
		public function get selectedIndexPath():SectionListIndexPath
		{
			return _contentView.selectedIndexPath;
		}
		
		/**
		 * 设置选中索引 
		 * @param value 选中索引
		 * 
		 */		
		public function set selectedIndexPath(value:SectionListIndexPath):void
		{
			_contentView.selectedIndexPath = value;
		}
		
		/**
		 * 重新加载数据 
		 * 
		 */		
		public function reloadData():void
		{
			_contentView.reloadData();
		}
		
		/**
		 * @inheritDoc
		 * 
		 */		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			this.graphics.clear();
			this.graphics.lineStyle(1, 0xe1e1e1);
			this.graphics.beginFill(0xffffff);
			this.graphics.drawRect(0,0,unscaledWidth, unscaledHeight);
			this.graphics.endFill();
			
			if(this.verticalScrollBar.visible)
			{
				_contentView.width = unscaledWidth - this.verticalScrollBar.width;
			}
			else
			{
				_contentView.width = unscaledWidth;
			}
			_contentView.height = unscaledHeight;
		}
	}
}