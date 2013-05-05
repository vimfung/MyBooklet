package cn.vimfung.mybooklet.framework.patch
{
	import cn.vimfung.common.db.SqliteDatabaseEvent;
	import cn.vimfung.common.db.SqliteDatabaseToken;
	import cn.vimfung.gnotes.kit.ISystemManager;
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.Utils;
	import cn.vimfung.mybooklet.framework.events.PatchEvent;
	
	import flash.data.SQLResult;
	import flash.events.EventDispatcher;
	import flash.events.IEventDispatcher;
	import flash.utils.Dictionary;
	
	/**
	 * 补丁成功 
	 */	
	[Event(name="patchSuccess", type="cn.vimfung.mybooklet.framework.events.PatchEvent")]
	
	/**
	 * 补丁失败 
	 */	
	[Event(name="patchFail", type="cn.vimfung.mybooklet.framework.events.PatchEvent")]
	
	/**
	 * 导入标签文章关系映射 
	 * @author Administrator
	 * 
	 * @since	ver1.4.0
	 * 
	 */	
	public class ImportTagNoteSetPatch extends EventDispatcher implements IPatchObject
	{
		/**
		 * 命令名称 
		 */		
		public static const NAME:String = "4C241D058902A5BD";
		
		public function ImportTagNoteSetPatch(target:IEventDispatcher=null)
		{
			super(target);
			
			_gnFacade = GNFacade.getInstance();
		}
		
		private var _gnFacade:GNFacade;
		
		/**
		 * @inheritDoc
		 */		
		public function start(system:ISystemManager):void
		{
			//查询所有有效文章
			var token:SqliteDatabaseToken = _gnFacade.documentDatabase.createCommandToken("SELECT id,tags FROM notes WHERE state=1");
			token.addEventListener(SqliteDatabaseEvent.RESULT, getAllNotesResultHandler);
			token.addEventListener(SqliteDatabaseEvent.ERROR, getAllNotesErrorHandler);
			token.start();
		}
		
		/**
		 * 获取所有文章返回 
		 * @param event 事件
		 * 
		 */		
		private function getAllNotesResultHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getAllNotesResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getAllNotesErrorHandler);
			
			var e:PatchEvent = null;
			
			if (event.recordset != null)
			{
				_gnFacade.documentDatabase.beginTrans();
				
				try
				{
					
					var clearToken:SqliteDatabaseToken = _gnFacade.documentDatabase.createCommandToken("DELETE FROM notes_tag_set");
					clearToken.startSync();
					
					for (var i:int = 0; i < event.recordset.length; i++)
					{
						var post:Object = event.recordset[i];
						if (post.tags != null)
						{
							var tagArr:Array = post.tags.split(";");
							tagArr = Utils.filterTags(tagArr);
							
							for (var j:int = 0; j < tagArr.length; j++)
							{
								var params:Dictionary = new Dictionary();
								params[":name"] = tagArr[j];
								var token:SqliteDatabaseToken = _gnFacade.documentDatabase.createCommandToken("SELECT id FROM notes_tag WHERE name = :name", params);
								var result:SQLResult = token.startSync();
								
								if (result.data != null && result.data.length > 0)
								{
									//添加标签
									params = new Dictionary();
									params[":tagId"] = result.data[0].id;
									params[":postId"] = post.id;
									
									var insertSetToken:SqliteDatabaseToken = _gnFacade.documentDatabase.createCommandToken("INSERT INTO notes_tag_set(tagId, noteId) VALUES(:tagId, :postId)", params);
									insertSetToken.startSync();
								}
							}
						}
					}
					
					_gnFacade.documentDatabase.commitTrans();
					
					//派发成功事件
					e = new PatchEvent(PatchEvent.PATCH_SUCCESS);
					e.name = ImportTagNoteSetPatch.NAME;
					this.dispatchEvent(e);
				}
				catch(err:Error)
				{
					_gnFacade.documentDatabase.rollbackTrans();
					
					//派发失败事件
					e = new PatchEvent(PatchEvent.PATCH_FAIL);
					e.error = err;
					this.dispatchEvent(e);
				}
			}
			else
			{
				e = new PatchEvent(PatchEvent.PATCH_SUCCESS);
				e.name = ImportTagNoteSetPatch.NAME;
				this.dispatchEvent(e);
			}
		}
		
		/**
		 * 获取所有文章失败 
		 * @param event 事件
		 * 
		 */		
		private function getAllNotesErrorHandler(event:SqliteDatabaseEvent):void
		{
			event.target.removeEventListener(SqliteDatabaseEvent.RESULT, getAllNotesResultHandler);
			event.target.removeEventListener(SqliteDatabaseEvent.ERROR, getAllNotesErrorHandler);
			
			var e:PatchEvent = new PatchEvent(PatchEvent.PATCH_FAIL);
			e.error = event.error;
			this.dispatchEvent(e);
		}
	}
}