package cn.vimfung.mybooklet.framework.module.myposts.ui
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.module.myposts.mediator.MyPostsMediator;
	
	import flash.events.MouseEvent;
	
	import spark.components.Group;
	import spark.components.Image;
	import spark.components.Label;
	
	/**
	 * SectionList的单元节头视图 
	 * @author Administrator
	 * 
	 */	
	public class SectionListHeaderView extends Group
	{
		public function SectionListHeaderView()
		{
			super();
			
			_background = new _bgImgCls();
			
			_titleLabel = new Label();
			_titleLabel.setStyle("color",0x808080);
			this.addElement(_titleLabel);
			
			_accessoryView = new Image();
			_accessoryView.source = new _accessoryViewCls();
			this.addElement(_accessoryView);
			
			if (_myPostMediator == null)
			{
				_myPostMediator = _facade.retrieveMediator(MyPostsMediator.NAME) as MyPostsMediator;
			}
		}
		
		private var _facade:GNFacade = GNFacade.getInstance();
		private var _myPostMediator:MyPostsMediator = null;
		private var _titleLabel:Label;
		private var _background:*;
		private var _accessoryView:Image;
		
		[Embed(source="assets/gnote/SectionHeaderBG.png")]
		private var _bgImgCls:Class;
		
		[Embed(source="assets/gnote/SectionHeaderAccessoryIcon.png")]
		private var _accessoryViewCls:Class;

		private var _data:Object;
		private var _isOpen:Boolean;
		
		/**
		 * @inheritDoc
		 * */
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			this.graphics.clear();
			this.graphics.beginBitmapFill(_background.bitmapData);
			this.graphics.drawRect(0, 0, unscaledWidth, unscaledHeight);
			this.graphics.endFill();
			
			if(_isOpen)
			{
				_accessoryView.x = 20;
				_accessoryView.y = 13;
			}
			else
			{
				_accessoryView.x = 10;
				_accessoryView.y = (this.height - _accessoryView.height) / 2;
			}
			
			_titleLabel.x = 25;
			_titleLabel.y = (this.height - _titleLabel.height) / 2;
			
			this.addEventListener(MouseEvent.CLICK, sectionHeaderClickHandler);
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
			
			_isOpen = _myPostMediator.tagPostsDataProvider.getSectionFlag(_data);
			_titleLabel.text = _data.name;
			if(_isOpen)
			{
				_accessoryView.rotation = 90;
			}
			else
			{
				_accessoryView.rotation = 0;
			}
		}
		
		/**
		 * 获取标题文本 
		 * @return 标题文本
		 * 
		 */		
		public function get label():String
		{
			return _titleLabel.text;
		}
		
		/**
		 * 设置标题文本 
		 * @param value 标题文本
		 * 
		 */		
		public function set label(value:String):void
		{
			_titleLabel.text = value;
		}
		
		/**
		 * 单元表头点击 
		 * @param event 事件
		 * 
		 */		
		private function sectionHeaderClickHandler(event:MouseEvent):void
		{
			_isOpen = !_isOpen;
			_myPostMediator.tagPostsDataProvider.setSectionFlag(_data, _isOpen);
			
			if(_isOpen)
			{
				_accessoryView.rotation = 90;
			}
			else
			{
				_accessoryView.rotation = 0;
			}
			
			_myPostMediator.refreshTagPosts(_data);
		}
	}
}