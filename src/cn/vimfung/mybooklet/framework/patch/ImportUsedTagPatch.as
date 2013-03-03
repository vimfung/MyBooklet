package cn.vimfung.mybooklet.framework.patch
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.db.SqliteDatabaseToken;
	import cn.vimfung.mybooklet.framework.events.PatchEvent;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.model.TagInfo;
	import cn.vimfung.mybooklet.framework.notification.SystemNotification;
	import cn.vimfung.gnotes.kit.ISystemManager;
	
	import flash.events.EventDispatcher;
	import flash.utils.Dictionary;
	
	import mx.controls.Alert;
	import mx.utils.StringUtil;
	
	/**
	 * 补丁成功 
	 */	
	[Event(name="patchSuccess", type="cn.vimfung.mybooklet.framework.events.PatchEvent")]
	
	/**
	 * 补丁失败 
	 */	
	[Event(name="patchFail", type="cn.vimfung.mybooklet.framework.events.PatchEvent")]
	
	/**
	 * 导入常用标签命令 
	 * @author Administrator
	 * 
	 */	
	public class ImportUsedTagPatch extends EventDispatcher implements IPatchObject
	{
		/**
		 * 命令名称 
		 */		
		public static const NAME:String = "D3C524E26F1DD2B2";
		
		public function ImportUsedTagPatch()
		{
			super();
			
			_gnFacade = GNFacade.getInstance();
			_tags = new Array();
		}
		
		private var _gnFacade:GNFacade;
		private var _tags:Array;
		
		/**
		 * 开始执行补丁 
		 * @param system 系统管理器
		 * 
		 */			
		public function start(system:ISystemManager):void
		{
			//查找所有文章标签
			var token:SqliteDatabaseToken = _gnFacade.documentDatabase.createCommandToken("SELECT tags FROM notes WHERE state = 1");
			token.addEventListener(SqliteDatabaseEvent.RESULT, getTagsResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, getTagFaultHandler);
			token.start();
		}
		
		/**
		 * 获取标签列表返回 
		 * @param event 事件
		 * 
		 */		
		private function getTagsResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getTagsResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getTagFaultHandler);
			
			var tmpTags:Array = event.recordset;
			if(tmpTags != null)
			{
				var tagInfo:TagInfo = null;
				for (var i:int = 0; i < tmpTags.length; i++)
				{
					var tagString:String = tmpTags[i].tags;
					var tags:Array = tagString.split(";");
					for (var j:int = 0; j < tags.length; j++)
					{
						var tag:String = StringUtil.trim(tags[j]);
						if(tag != "")
						{
							var exists:Boolean = false;
							for (var n:int = 0; n < _tags.length; n ++)
							{
								tagInfo = _tags[n];
								if(tagInfo.name == tag)
								{
									tagInfo.useCount++;
									exists = true;
									break;
								}
							}
							
							if(!exists)
							{
								tagInfo = new TagInfo();
								tagInfo.name = tag;
								tagInfo.useCount = 1;
								tagInfo.createTime = new Date();
								tagInfo.latestTime = tagInfo.createTime;
								_tags.push(tagInfo);
							}
						}
					}
				}
			}
			
			var e:PatchEvent = null;
			
			if(_tags.length > 0)
			{
				_gnFacade.documentDatabase.beginTrans();
				try
				{
					//删除所有标签
					var token:SqliteDatabaseToken = _gnFacade.documentDatabase.createCommandToken("DELETE FROM notes_tag");
					token.start();
					
					for (var m:int = 0; m < _tags.length; m++)
					{
						
						
						tagInfo = _tags[m];
						var param:Dictionary = new Dictionary();
						param[":name"] = tagInfo.name;
						param[":createTime"] = tagInfo.createTime;
						param[":latestTime"] = tagInfo.latestTime;
						param[":useCount"] = tagInfo.useCount;
						
						token = _gnFacade.documentDatabase.createCommandToken("INSERT INTO notes_tag(name, createTime, latestTime, useCount) VALUES(:name, :createTime, :latestTime, :useCount)", param);
						token.start();
					}

					_gnFacade.documentDatabase.commitTrans();
					
					e = new PatchEvent(PatchEvent.PATCH_SUCCESS);
					e.name = ImportUsedTagPatch.NAME;
					this.dispatchEvent(e);
				}
				catch(err:Error)
				{
					_gnFacade.documentDatabase.rollbackTrans();
					
					e = new PatchEvent(PatchEvent.PATCH_FAIL);
					e.error = err;
					this.dispatchEvent(e);
				}
			}
			else
			{
				e = new PatchEvent(PatchEvent.PATCH_SUCCESS);
				e.name = ImportUsedTagPatch.NAME;
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 获取标签列表失败 
		 * @param event 事件
		 * 
		 */		
		private function getTagFaultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getTagsResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getTagFaultHandler);
			
			var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_FAIL);
			e.error = event.error;
			this.dispatchEvent(e);
		}
	}
}