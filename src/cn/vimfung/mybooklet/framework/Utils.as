package cn.vimfung.mybooklet.framework
{
	/**
	 * 工具类 
	 * @author Administrator
	 * 
	 */	
	public class Utils extends Object
	{
		public function Utils()
		{
			super();
		}
		
		/**
		 * 过滤重复标签 
		 * @param tags 标签数组
		 * @return 过滤后标签数组
		 * 
		 */		
		public static function filterTags(tags:Array):Array
		{
			for (var i:int = 0; i < tags.length; i++)
			{
				var tag:String = tags[i];
				
				var index:int = i + 1;
				while (index < tags.length)
				{
					var nextTag:String = tags[index];
					if (tag == nextTag)
					{
						tags.splice(index,1);
						continue;
					}
					
					index++;
				}
			}
			
			return tags;
		}
	}
}