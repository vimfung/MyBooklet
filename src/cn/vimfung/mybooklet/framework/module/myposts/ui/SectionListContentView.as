package cn.vimfung.mybooklet.framework.module.myposts.ui
{
	import cn.vimfung.mybooklet.framework.module.myposts.events.SectionListEvent;
	import cn.vimfung.mybooklet.framework.module.myposts.model.SectionListDataProvider;
	import cn.vimfung.mybooklet.framework.module.myposts.model.SectionListIndexPath;
	
	import flash.events.MouseEvent;
	import flash.utils.ByteArray;
	import flash.utils.Dictionary;
	import flash.utils.getTimer;
	
	import spark.components.Group;
	import spark.core.IViewport;
	import spark.core.NavigationUnit;
	
	/**
	 * SectionList内容视图 
	 * @author Administrator
	 * 
	 */	
	public class SectionListContentView extends Group
	{
		public function SectionListContentView()
		{
			super();
			
			_reuseItemPool = new Array();
			_reuseSectionPool = new Array();
			_visibleItem = new Dictionary();
			_visibleSections = new Dictionary();
			_sectionMaping = new Array();
			
			_visibleStartIndexPath = new SectionListIndexPath();
			
			_startIndexPath = new SectionListIndexPath();
			_startIndexPath.section = 0;
			_startIndexPath.row = 0;
			_endIndexPath = new SectionListIndexPath();
			_endIndexPath.section  -1;
			_endIndexPath.row = - 1;
			
			_visibleStartIndex = -1;
			_curPos = 0;
		}
		
		internal static const ROW_HEIGHT:Number = 82;
		internal static const SECTION_HEIGHT:Number = 32;
		
		private var _rowCount:int;
		private var _contentHeight:Number;
		private var _reuseItemPool:Array;
		private var _visibleItem:Dictionary;
		private var _reuseSectionPool:Array;
		private var _visibleSections:Dictionary;
		
		private var _needLayout:Boolean;
		private var _layoutItems:Boolean;
		private var _renderer:Boolean;
		private var _visibleStartIndex:int;
		
		private var _sectionMaping:Array;				//分节映射表
		private var _curPos:Number;
		
		private var _dataProvider:SectionListDataProvider;
		private var _visibleStartIndexPath:SectionListIndexPath;
		
		private var _startIndexPath:SectionListIndexPath;
		private var _endIndexPath:SectionListIndexPath;
		private var _selectedIndexPath:SectionListIndexPath;
		
		/**
		 * 获取选中索引 
		 * @return 选中索引
		 * 
		 */		
		public function get selectedIndexPath():SectionListIndexPath
		{
			return _selectedIndexPath;
		}
		
		/**
		 * 设置选中索引 
		 * @param value 选中索引
		 * 
		 */		
		public function set selectedIndexPath(value:SectionListIndexPath):void
		{
			_selectedIndexPath = value;
		}
		
		/**
		 * 获取选中项目 
		 * @return 选中项目
		 * 
		 */		
		public function get selectedItem():*
		{
			if (_dataProvider != null && _selectedIndexPath != null)
			{
				return _dataProvider.getValue(_dataProvider.getSection(_selectedIndexPath.section), _selectedIndexPath.row);
			}
			return null;
		}
		
		/**
		 * 设置选中项目 
		 * @param value 选中项目
		 * 
		 */		
		public function set selectedItem(value:*):void
		{
			if (value == null)
			{
				this.selectedIndexPath = null;
				return;
			}
			
			if (_dataProvider != null)
			{
				for (var i:int = 0; i < _dataProvider.sectionCount; i++)
				{
					var section:Object = _dataProvider.getSection(i);
					var count:int = _dataProvider.getExpandSectionDataLength(section);
					var match:Boolean = false;
					for (var j:int = 0; j < count; j ++)
					{
						var data:Object = _dataProvider.getValue(section,j);
						if (data == value)
						{
							var selectedIndexPath:SectionListIndexPath = new SectionListIndexPath();
							selectedIndexPath.section = i;
							selectedIndexPath.row = j;
							
							this.selectedIndexPath = selectedIndexPath;
							
							match = true;
							break;
						}
					}
					
					if (match)
					{
						break;
					}
				}
			}
		}

		/**
		 * 获取数据源 
		 * @return 数据源
		 * 
		 */		
		public function get dataProvider():SectionListDataProvider
		{
			return _dataProvider;
		}

		/**
		 * 设置数据源 
		 * @param value 数据源
		 * 
		 */		
		public function set dataProvider(value:SectionListDataProvider):void
		{
			_dataProvider = value;
			
			this.reloadData();
		}

		/**
		 * 获取行数 
		 * @return 行数 
		 * 
		 */		
		public function get rowCount():int
		{
			return _rowCount;
		}

		/**
		 * 设置行数 
		 * @param value 行数
		 * 
		 */		
		public function set rowCount(value:int):void
		{
			_rowCount = value;
			_contentHeight = _rowCount * ROW_HEIGHT + _sectionMaping.length * SECTION_HEIGHT;
		}

		/**
		 * @inheritDoc
		 * 
		 */		
		override public function get contentHeight():Number
		{
			return _contentHeight;
		}
		
		/**
		 * @inheritDoc
		 * 
		 */
		override public function set width(value:Number):void
		{
			_layoutItems = true;
			super.width = value;
		}
		
		/**
		 * @inheritDoc
		 * 
		 */
		override public function set verticalScrollPosition(value:Number):void
		{
			super.verticalScrollPosition = value;
			
			this.rendererSections();
			
			_needLayout = true;
			this.invalidateDisplayList();
		}
		
		/**
		 * 刷新数据 
		 * 
		 */		
		public function reloadData():void
		{
			//计算总行数
			var i:String;
			var rowCount:int = this.refreshTotalCount();
			if (rowCount != this.rowCount)
			{				
				_renderer = true;
			}
			this.rowCount = rowCount;
			
			for (i in _visibleItem)
			{
				var item:TagPostItemRenderer = _visibleItem[i] as TagPostItemRenderer;
				item.data = _dataProvider.getValue(_dataProvider.getSection(item.indexPath.section), item.indexPath.row);
				
				//调整位置
				if(item.indexPath.section == 0)
				{
					item.y = item.indexPath.row * ROW_HEIGHT + (item.indexPath.section + 1) * SECTION_HEIGHT;
				}
				else
				{
					item.y = (item.indexPath.row + _sectionMaping[item.indexPath.section - 1]) * ROW_HEIGHT + (item.indexPath.section + 1) * SECTION_HEIGHT;
				}
				item.x = 0;
				item.width = this.width;
				item.height = ROW_HEIGHT;
			}
			
			_needLayout = true;
			this.invalidateDisplayList();
		}
		
		/**
		 * @inheritDoc
		 */		
		override protected function updateDisplayList(unscaledWidth:Number, unscaledHeight:Number):void
		{
			super.updateDisplayList(unscaledWidth, unscaledHeight);
			
			if(_needLayout)
			{
				_needLayout = false;
				//计算显示的起始项索引
				this.refreshVisibleStartIndex();
				this.rendererSections();
				if (_renderer)
				{
					_renderer = false;
					this.rendererItems();
				}
			}
			else if(_layoutItems)
			{
				_layoutItems = false;
				
				var k:String;
				
				for (k in _visibleItem)
				{
					var item:TagPostItemRenderer = _visibleItem[k] as TagPostItemRenderer;
					if (item != null)
					{
						item.width = this.width;
					}
				}
				
				for (k in _visibleSections)
				{
					var header:SectionListHeaderView = _visibleSections[k] as SectionListHeaderView;
					if (header != null)
					{
						header.width = this.width;
					}
				}
			}
		}
		
		/**
		 * 获取数据 
		 * @param index 索引
		 * @return 数据对象
		 * 
		 */		
		private function getData(index:int):Object
		{
			var preIndex:int = 0;
			for(var i:int = 0; i <_sectionMaping.length; i++)
			{
				if (_sectionMaping[i] > index)
				{
					return _dataProvider.getValue(_dataProvider.getSectionName(i), index - preIndex);
				}
				
				preIndex = _sectionMaping[i];
			}
			
			return null;
		}
		
		/**
		 * 渲染列表项 
		 * 
		 */		
		private function rendererItems():void
		{
			var item:TagPostItemRenderer = null;
			var e:SectionListEvent;
			var i:int = 0;
			var j:int = 0;
			var key:String;
			var sectionLength:int;
			
			var top:Number = _visibleStartIndex * ROW_HEIGHT + _visibleStartIndexPath.section * SECTION_HEIGHT;
			
			var visibleItems:Array = new Array();		//记录需要显示的Key
			var endIndexPath:SectionListIndexPath = new SectionListIndexPath();
			endIndexPath.section = -1;
			endIndexPath.row = -1;
			
			var tmpIndexPath:SectionListIndexPath = new SectionListIndexPath();
			//计算结束显示索引
			for (i = _visibleStartIndexPath.section; i < _dataProvider.sectionCount; i++)
			{
				endIndexPath.section = i;
				endIndexPath.row = -1;
				top += SECTION_HEIGHT;
				
				if (top > this.verticalScrollPosition + this.height)
				{
					break;
				}
				
				var hasOver:Boolean = false;
				
				sectionLength = _dataProvider.getExpandSectionDataLength(_dataProvider.getSection(i));
				j = 0;
				if (i == _visibleStartIndexPath.section)
				{
					j = _visibleStartIndexPath.row;
				}
				
				for (; j < sectionLength; j++)
				{
					endIndexPath.row = j;
					top += ROW_HEIGHT;
					if (top > this.verticalScrollPosition + this.height)
					{
						hasOver = true;
						break;
					}
				}
				
				if(hasOver)
				{
					break;
				}
			}
			
			//创建将要显示项目
			var row:int = _visibleStartIndexPath.row == -1 ? 0 : _visibleStartIndexPath.row;
			if(_visibleStartIndexPath.section == 0)
			{
				top = row * ROW_HEIGHT + (_visibleStartIndexPath.section + 1) * SECTION_HEIGHT;
			}
			else
			{
				top = (_sectionMaping[_visibleStartIndexPath.section - 1] + row) * ROW_HEIGHT + (_visibleStartIndexPath.section + 1) * SECTION_HEIGHT;
			}
			
			for (i = _visibleStartIndexPath.section; i <= endIndexPath.section; i++)
			{
				if (i == -1)
				{
					continue;
				}
				if (i == _visibleStartIndexPath.section)
				{
					j = _visibleStartIndexPath.row;
				}
				else
				{
					j = 0;
				}
				
				if (i == endIndexPath.section)
				{
					sectionLength = endIndexPath.row + 1;
				}
				else
				{
					sectionLength = _dataProvider.getExpandSectionDataLength(_dataProvider.getSection(i));
				}
				
				for (; j < sectionLength; j++)
				{
					if(j == -1)
					{
						continue;
					}
					
					tmpIndexPath.section = i;
					tmpIndexPath.row = j;
					
					//记录Key
					key = "item_" + tmpIndexPath.section + "_" + tmpIndexPath.row;
					visibleItems.push(key);
					
					if (!this.isVisibleItem(key))
					{
						//派发事件
						e = new SectionListEvent(SectionListEvent.ITEM_WILL_DISPLAY);
						e.indexPath = tmpIndexPath;
						this.owner.parent.dispatchEvent(e);
						
						//创建列表项
						item = this.getItemRenderer(tmpIndexPath);
						item.x = 0;
						item.y = top;
						item.width = this.width;
						item.height = ROW_HEIGHT;
						item.data = _dataProvider.getValue(_dataProvider.getSection(i), j);
						
						if (!this.contains(item))
						{
							this.addElementAt(item, 0);
						}
					}
					
					top += ROW_HEIGHT;
				}
				
				top += SECTION_HEIGHT;
			}
			
			_startIndexPath.section = _visibleStartIndexPath.section;
			_startIndexPath.row = _visibleStartIndexPath.row;
			_endIndexPath.section = endIndexPath.section;
			_endIndexPath.row = endIndexPath.row;
			
			//回收项目
			for (key in _visibleItem)
			{
				if (visibleItems.indexOf(key) == -1)
				{
					this.recoverItemRenderer(key);
				}
			}
		}
		
		/**
		 * 渲染单元节头视图 
		 * 
		 */		
		private function rendererSections():void
		{
			var index:int = 0;
			var key:String;
			var headerView:SectionListHeaderView;
			var visibleSections:Array = new Array();
			
			for (var j:int = _visibleStartIndexPath.section; j < _sectionMaping.length; j++)
			{
				var top:Number = 0;
				if (index == 0)
				{
					var pos:Number = _sectionMaping[j] * ROW_HEIGHT + (j + 1) * SECTION_HEIGHT;
					if(pos - this.verticalScrollPosition < SECTION_HEIGHT)
					{
						top = pos - SECTION_HEIGHT;
					}
					else
					{
						top = this.verticalScrollPosition;
					}
				}
				else
				{
					top = _sectionMaping[j - 1] * ROW_HEIGHT + j * SECTION_HEIGHT;
				}
				
				if(top > this.verticalScrollPosition + this.height)
				{
					break;
				}
				
				key = "section_" + j;
				visibleSections.push(key);
				if (!this.isVisibleSection(key))
				{
					var e:SectionListEvent = new SectionListEvent(SectionListEvent.SECTION_WILL_DISPLAY);
					e.section = j;
					this.owner.parent.dispatchEvent(e);
					
					headerView = this.getSectionHeaderView(key);
					
					headerView.x = 0;
					headerView.y = top;
					headerView.width = this.width;
					headerView.height = SECTION_HEIGHT;
					headerView.data = _dataProvider.getSection(j);
					
					if(!this.containsElement(headerView))
					{
						this.addElement(headerView);
					}
				}
				else
				{
					headerView = this.getSectionHeaderView(key);
					
					headerView.x = 0;
					headerView.y = top;
					headerView.width = this.width;
					headerView.height = SECTION_HEIGHT;
				}
				
				index ++;
			}
			
			//回收项目
			for (key in _visibleSections)
			{
				if (visibleSections.indexOf(key) == -1)
				{
					this.recoverSectionHeaderView(key);
				}
			}
		}
		
		/**
		 * 是否为显示列表项 
		 * @param key 列表项应用键
		 * @return true 显示， false 未显示
		 * 
		 */		
		private function isVisibleItem(key:String):Boolean
		{
			return _visibleItem[key] == null ? false : true;
		}
		
		/**
		 * 是否为显示Section 
		 * @param key Section引用键
		 * @return true 显示， false 未显示
		 * 
		 */		
		private function isVisibleSection(key:String):Boolean
		{
			return _visibleSections[key] == null ? false : true;
		}
		
		/**
		 * 获取项目渲染器 
		 * @param index 位置索引
		 * @return 项目渲染器
		 * 
		 */		
		private function getItemRenderer(indexPath:SectionListIndexPath):TagPostItemRenderer
		{
			var key:String = "item_" + indexPath.section + "_" + indexPath.row;
	
			var itemRenderer:TagPostItemRenderer = _visibleItem[key];
			if (itemRenderer == null && _reuseItemPool.length > 0)
			{
				itemRenderer = _reuseItemPool.shift();
				_visibleItem[key] = itemRenderer;
			}
			
			if (itemRenderer == null)
			{
				itemRenderer = new TagPostItemRenderer();
				itemRenderer.addEventListener(MouseEvent.CLICK, itemClickHandler);
				_visibleItem[key] = itemRenderer;
			}
			
			itemRenderer.indexPath = new SectionListIndexPath();
			itemRenderer.indexPath.section = indexPath.section;
			itemRenderer.indexPath.row = indexPath.row;
			
			return itemRenderer;
		}
		
		/**
		 * 回收项目渲染器 
		 * @param startIndex 回收起始索引
		 * 
		 */		
		private function recoverItemRenderer(key:String):void
		{
			var itemRenderer:TagPostItemRenderer = _visibleItem[key];
			if (itemRenderer != null)
			{
				if (this.containsElement(itemRenderer))
				{
					this.removeElement(itemRenderer);
				}
				_reuseItemPool.push(itemRenderer);
			}
			
			_visibleItem[key] = null;
			delete _visibleItem[key];
		}
		
		/**
		 * 获取单元节表头
		 * @param key Section引用键
		 * @return 表头视图
		 * 
		 */		
		private function getSectionHeaderView(key:String):SectionListHeaderView
		{
			var headerView:SectionListHeaderView = _visibleSections[key];
			

			if (headerView == null && _reuseSectionPool.length > 0)
			{
				headerView = _reuseSectionPool.shift();
				_visibleSections[key] = headerView;
			}
			
			if (headerView == null)
			{
				headerView = new SectionListHeaderView();
				_visibleSections[key] = headerView;
			}
			
			return headerView;
		}
		
		/**
		 * 回收单元节表头视图 
		 * @param startIndex 起始位置索引
		 * 
		 */		
		private function recoverSectionHeaderView(key:String):void
		{
			var headerView:SectionListHeaderView = _visibleSections[key];
			if (headerView != null)
			{
				if (this.containsElement(headerView))
				{
					this.removeElement(headerView);
				}
				_reuseSectionPool.push(headerView);
			}
			
			_visibleSections[key] = null;
			delete _visibleSections[key];
		}
		
		/**
		 * 刷新列表行数 
		 * @return 行数
		 * 
		 */		
		private function refreshTotalCount():int
		{
			_sectionMaping.splice(0);
			
			var rowCount:int = 0;
			if (_dataProvider != null)
			{
				for (var i:int = 0; i <_dataProvider.sectionCount; i++)
				{
					var section:Object = _dataProvider.getSection(i);
					rowCount += _dataProvider.getExpandSectionDataLength(section);
					
					_sectionMaping.push(rowCount);
				}
			}
			
			return rowCount;
		}
		
		/**
		 * 刷新显示起始索引 
		 * 
		 */		
		private function refreshVisibleStartIndex():void
		{
			var i:int = 0;
			var j:int = 0;
			var startRow:int = 0;
			var startPos:Number = 0;
			var newStartIndex:int = _visibleStartIndex;
			
			if(_curPos > this.verticalScrollPosition)
			{
				//向上滚动
				for (i = _visibleStartIndexPath.section; i >= 0; i--)
				{
					//取前一Section中的最大行数,并计算该Section的最大范围
					if (i - 1 < 0)
					{
						startRow = 0;
					}
					else
					{
						startRow = _sectionMaping[i - 1];
					}
					startPos = startRow * ROW_HEIGHT + i * SECTION_HEIGHT;
					
					if (startPos  < this.verticalScrollPosition || i == 0)
					{
						//在此Section范围内,判断在哪一行中
						_visibleStartIndexPath.section = i;
						_visibleStartIndexPath.row = _dataProvider.getExpandSectionDataLength(_dataProvider.getSection(i));
						if (_visibleStartIndexPath.row == 0)
						{
							_visibleStartIndexPath.row = -1;
						}
						startPos += SECTION_HEIGHT;
						
						//取前一Section最大行数
						for (j = startRow; j < _sectionMaping[i]; j++)
						{
							startPos += ROW_HEIGHT;
							if (startPos > this.verticalScrollPosition)
							{
								_visibleStartIndexPath.row = j - startRow;
								newStartIndex = j;
								break;
							}
						}
						break;
					}
				}
			}
			else if (_curPos <= this.verticalScrollPosition)
			{
				//向下滚动
				for (i = _visibleStartIndexPath.section; i < _sectionMaping.length; i++)
				{
					//取前一Section中的最大行数,并计算该Section的最大范围
					startRow = _sectionMaping[i];
					startPos = startRow * ROW_HEIGHT + (i + 1) * SECTION_HEIGHT;
					
					if (startPos  > this.verticalScrollPosition)
					{
						//在此Section范围内,判断在哪一行中
						_visibleStartIndexPath.section = i;
						_visibleStartIndexPath.row = -1;
						
						//取前一Section最大行数
						if (i - 1 < 0)
						{
							startRow = 0;
						}
						else
						{
							startRow = _sectionMaping[i-1];
						}
						
						startPos = startRow * ROW_HEIGHT + (i + 1) * SECTION_HEIGHT;
						
						for (j = startRow; j < _sectionMaping[i]; j++)
						{
							startPos += ROW_HEIGHT;
							if (startPos > this.verticalScrollPosition)
							{
								newStartIndex = j;
								_visibleStartIndexPath.row = newStartIndex - startRow;
								
								break;
							}
						}
						
						break;
					}
				}
			}
	
			if (_visibleStartIndexPath.section == 0)
			{
				newStartIndex = _visibleStartIndexPath.row;
			}
			else
			{
				newStartIndex = _sectionMaping[_visibleStartIndexPath.section - 1] + _visibleStartIndexPath.row; 
			}
			
			if (newStartIndex != _visibleStartIndex)
			{
				_renderer = true;
				_visibleStartIndex = newStartIndex;
			}
			_curPos = this.verticalScrollPosition >= 0 ? this.verticalScrollPosition : 0;
		}
		
		/**
		 * @inheritDoc
		 */	
		override public function getVerticalScrollPositionDelta(navigationUnit:uint):Number
		{
			switch(navigationUnit)
			{
				case NavigationUnit.DOWN:
					return ROW_HEIGHT;
				case NavigationUnit.UP:
					return -ROW_HEIGHT;
				default:
					return -1;
			}
			
		}
		
		/**
		 * 列表项点击 
		 * @param event 事件
		 * 
		 */		
		private function itemClickHandler(event:MouseEvent):void
		{
			var indexPath:SectionListIndexPath = (event.currentTarget as TagPostItemRenderer).indexPath;
			
			if(_selectedIndexPath == null || _selectedIndexPath.section != indexPath.section || _selectedIndexPath.row != indexPath.row)
			{
				_selectedIndexPath = indexPath;
				
				var e:SectionListEvent = new SectionListEvent(SectionListEvent.ITEM_CLICK);
				e.indexPath = (event.currentTarget as TagPostItemRenderer).indexPath;
				this.owner.parent.dispatchEvent(e);
			}
		}
	}
}