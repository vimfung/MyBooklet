package cn.vimfung.mybooklet.framework.module.myposts.model
{
	import flash.utils.Dictionary;

	/**
	 * SectionList的数据源 
	 * @author Administrator
	 * 
	 */	
	public class SectionListDataProvider extends Object
	{
		public function SectionListDataProvider()
		{
			super();
			
			_source = new Dictionary();
			_sectionFlags = new Dictionary();
			_keys = new Array();
		}
		
		private var _source:Dictionary;
		private var _sectionFlags:Dictionary;
		private var _keys:Array;
		
		/**
		 * 转换小节名称 
		 * @param data 数据
		 * @return 名称
		 * 
		 */		
		protected function convertSectionName(data:Object):String
		{
			return data.name;
		}
		
		/**
		 * 获取单元数量 
		 * @return 数量
		 * 
		 */		
		public function get sectionCount():int
		{
			return _keys.length;
		}
		
		/**
		 * 检测是否包含指定小节
		 * @param section 小节对象
		 * @return true 存在， false 不存在
		 * 
		 */		
		public function containsSection(section:Object):Boolean
		{
			var keyName:String = this.convertSectionName(section);
			return _source[keyName] == null ? false : true;
		}
		
		/**
		 * 获取单元名称 
		 * @param index 位置索引
		 * @return 名称
		 * 
		 */		
		public function getSectionName(index:int):String
		{
			return this.convertSectionName(_keys[index]);
		}
		
		/**
		 * 获取小节对象 
		 * @param index 位置索引
		 * @return 小节对象
		 * 
		 */		
		public function getSection(index:int):Object
		{
			return _keys[index];
		}
		
		/**
		 * 获取单元数据长度 
		 * @param section 小节对象
		 * @return 数据长度
		 * 
		 */		
		public function getSectionDataLength(section:Object):int
		{
			var keyName:String = this.convertSectionName(section);
			if(_sectionFlags[keyName] && _source[keyName] != null)
			{
				return (_source[keyName] as Array).length;
			}
			return 0;
		}
		
		/**
		 * 设置单元状态 
		 * @param section 单元名称
		 * @param flag 状态
		 * 
		 */		
		public function setSectionFlag(section:Object, flag:Boolean):void
		{
			var keyName:String = this.convertSectionName(section);
			if (_source[keyName] == null)
			{
				_source[keyName] = new Array();
				_keys.push(section);
			}
			_sectionFlags[keyName] = flag;
		}
		
		/**
		 * 获取小节状态 
		 * @param section 小节对象
		 * @return true 表示展开，false 表示折叠
		 * 
		 */		
		public function getSectionFlag(section:Object):Boolean
		{
			var keyName:String = this.convertSectionName(section);
			if (_sectionFlags[keyName] != null)
			{
				return _sectionFlags[keyName];
			}
			
			return false;
		}
		
		/**
		 * 添加值 
		 * @param data 数据
		 * @param section 单元节
		 * 
		 */		
		public function addValue(data:Object, section:Object):void
		{
			var keyName:String = this.convertSectionName(section);
			var list:Array = _source[keyName];
			if(list == null)
			{
				list = new Array();
				_source[keyName] = list;
				_sectionFlags[keyName] = false;
				_keys.push(section);
			}
			
			list.push(data);
		}
		
		/**
		 * 插入值 
		 * @param data 数据
		 * @param index 位置索引
		 * @param section 单元节
		 * 
		 */		
		public function insertValue(data:Object, index:int, section:Object):void
		{
			var keyName:String = this.convertSectionName(section);
			var list:Array = _source[keyName];
			if(list == null)
			{
				list = new Array();
				_source[keyName] = list;
				_sectionFlags[keyName] = false;
				_keys.push(section);
			}
			
			list.splice(index, 0, data);
		}
		
		/**
		 * 添加多个值 
		 * @param array 值数组
		 * @param section 下节对象
		 * 
		 */		
		public function addValues(array:Array, section:Object):void
		{
			var keyName:String = this.convertSectionName(section);
			var list:Array = _source[keyName];
			if(list == null)
			{
				list = new Array();
				_source[keyName] = list;
				_sectionFlags[keyName] = false;
				_keys.push(section);
			}
			
			for(var i:int = 0; i< array.length; i++)
			{
				list.push(array[i]);
			}			
		}
		
		/**
		 * 获取值 
		 * @param section 单元节
		 * @param index 位置索引
		 * @return 值
		 * 
		 */		
		public function getValue(section:Object,index:int):Object
		{
			var keyName:String = this.convertSectionName(section);
			var list:Array = _source[keyName];
			if(list != null)
			{
				return list[index];
			}
			
			return null;
		}
		
		/**
		 * 获取单元所有值集合 
		 * @param section 单元节
		 * @return 值集合
		 * 
		 */		
		public function getValues(section:Object):Array
		{
			var keyName:String = this.convertSectionName(section);
			return _source[keyName];
		}
		
		/**
		 * 添加单元 
		 * @param section 单元名称
		 * 
		 */		
		public function addSection(section:Object):void
		{
			var keyName:String = this.convertSectionName(section);
			if(_source[keyName] == null)
			{
				_source[keyName] = new Array();
				_sectionFlags[keyName] = false;
				_keys.push(section);
			}
		}
		
		/**
		 * 删除值 
		 * @param data 数据
		 * @param section 单元节
		 * 
		 */		
		public function removeValue(data:Object, section:Object):void
		{
			var keyName:String = this.convertSectionName(section);
			var list:Array = _source[keyName];
			if(list != null)
			{
				var index:int = list.indexOf(data);
				if (index != -1)
				{
					list.splice(index, 1);
				}
			}
		}
	}
}