package cn.vimfung.mybooklet.framework.module.myposts.mediator
{
	import cn.vimfung.mybooklet.framework.GNFacade;
	import cn.vimfung.mybooklet.framework.events.SqliteDatabaseEvent;
	import cn.vimfung.mybooklet.framework.module.myposts.Constant;
	import cn.vimfung.mybooklet.framework.module.myposts.IMyPosts;
	import cn.vimfung.mybooklet.framework.module.myposts.MyPosts;
	import cn.vimfung.mybooklet.framework.module.myposts.PostToken;
	import cn.vimfung.mybooklet.framework.module.myposts.events.PostEvent;
	import cn.vimfung.mybooklet.framework.module.myposts.events.SectionListEvent;
	import cn.vimfung.mybooklet.framework.module.myposts.model.AttachmentInfo;
	import cn.vimfung.mybooklet.framework.module.myposts.model.PostsRequestData;
	import cn.vimfung.mybooklet.framework.module.myposts.model.SectionListDataProvider;
	import cn.vimfung.mybooklet.framework.module.myposts.model.TagPostListState;
	import cn.vimfung.mybooklet.framework.module.myposts.notification.PostNotification;
	import cn.vimfung.mybooklet.framework.module.myposts.proxy.MyPostsProxy;
	import cn.vimfung.mybooklet.framework.notification.SystemNotification;
	import cn.vimfung.utils.Encode;
	
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.html.HTMLLoader;
	import flash.system.ApplicationDomain;
	import flash.system.System;
	import flash.utils.ByteArray;
	
	import mx.collections.ArrayCollection;
	import mx.controls.HTML;
	import mx.utils.StringUtil;
	
	import org.puremvc.as3.interfaces.IMediator;
	import org.puremvc.as3.interfaces.INotification;
	import org.puremvc.as3.patterns.mediator.Mediator;
	
	import spark.components.HGroup;
	
	/**
	 * 我的文章访问器 
	 * @author Administrator
	 * 
	 */	
	public class MyPostsMediator extends Mediator implements IMediator
	{
		public static const NAME:String = "MyPostsMediator";
		public static const PAGE_SIZE:Number = 30;
		
		public function MyPostsMediator(viewComponent:IMyPosts)
		{
			super(MyPostsMediator.NAME, viewComponent);
			
			_gnFacade = this.facade as GNFacade;
			_postProxy = _gnFacade.retrieveProxy(MyPostsProxy.NAME) as MyPostsProxy;
			_myPostsModule = viewComponent;
			
			_keyword = null;
			_postsList = new ArrayCollection();
			_hasMore = false;
		}
		
		private var _gnFacade:GNFacade;
		private var _postProxy:MyPostsProxy;
		private var _myPostsModule:IMyPosts;
		
		private var _reloadList:Boolean;
		private var _color:uint;
		private var _keyword:String;
		private var _postsList:ArrayCollection;
		private var _hasMore:Boolean;
		
		private var _tagPostListState:TagPostListState;
		private var _sectionListDataProvider:SectionListDataProvider;
		
		private var _token:PostToken;
		
		/**
		 * 获取文章模块对象 
		 * @return 文章模块对象
		 * 
		 */		
		public function get module():IMyPosts
		{
			return _myPostsModule;
		}
		
		/**
		 * 获取文章列表数据 
		 * @return 文章列表数据
		 * 
		 */		
		public function get postsList():ArrayCollection
		{
			return _postsList;
		}
		
		/**
		 * 获取标签文章列表数据源 
		 * @return 标签文章列表数据源
		 * 
		 */		
		public function get tagPostsDataProvider():SectionListDataProvider
		{
			return _sectionListDataProvider;
		}
		
		/**
		 * 初始化标签文章列表 
		 * 
		 */		
		public function initTagPostList():void
		{
			if(_tagPostListState == null)
			{
				var defaultTag:Object = new Object();
				defaultTag.id = 0;
				defaultTag.name = "默认";
				
				_tagPostListState = new TagPostListState();
				_sectionListDataProvider = new SectionListDataProvider();
				_sectionListDataProvider.addSection(defaultTag);
				_myPostsModule.postListView.liTagPost.dataProvider = _sectionListDataProvider;
				
				//获取标签列表
				var token:PostToken = _postProxy.getTags(1);
				token.addEventListener(PostEvent.GET_TAGS_RESULT,getTagsResultHandler);
				token.addEventListener(PostEvent.GET_TAGS_ERROR, getTagsErrorHandler);
				token.start();
				
				//监听列表项将要显示事件，当每个Section最后一项显示时则加载数据
				this.module.postListView.liTagPost.addEventListener(SectionListEvent.ITEM_WILL_DISPLAY, itemWillDisplayHandler);
				this.module.postListView.liTagPost.addEventListener(SectionListEvent.ITEM_CLICK, postItemClickHandler);
				this.module.postListView.liTagPost.addEventListener(SectionListEvent.SECTION_WILL_DISPLAY, sectionWillDisplayHandler);
			}
		}
		
		/**
		 * 刷新标签文章列表
		 * @param tagInfo 标签信息
		 * 
		 */		
		public function refreshTagPosts(tagInfo:Object):void
		{
			if(_tagPostListState.tagPostsState[tagInfo.id] == null)
			{
				_tagPostListState.tagPostsState[tagInfo.id] = {more:false};
				
				//加载数据
				var token:PostToken = _postProxy.getPostsByTag(tagInfo, null, PAGE_SIZE);
				token.addEventListener(PostEvent.GET_POSTS_RESULT, getTagPostsResultHandler);
				token.addEventListener(PostEvent.GET_POSTS_ERROR, getTagPostsFaultHandler);
				token.start();
			}
			else
			{
				_myPostsModule.postListView.liTagPost.reloadData();
			}
		}
		
		/**
		 * @inheritDoc
		 */		
		public override function listNotificationInterests():Array
		{
			return [PostNotification.BEGIN_REFRESH_LIST,
				PostNotification.UPDATE_POST,
				PostNotification.DELETE_POST,
				PostNotification.ADD_POST,
				SystemNotification.FULL_SCREEN];
		}
		
		/**
		 * @inheritDoc
		 * 
		 */		
		public override function handleNotification(notification:INotification):void
		{
			switch(notification.getName())
			{
				case PostNotification.BEGIN_REFRESH_LIST:
				{
					_reloadList = true;
					
					var body:PostsRequestData = notification.getBody() as PostsRequestData;
					var keyword:String = null;
					var color:uint = 0xffffff;
					if(body != null)
					{
						if(body.keyword is String)
						{
							keyword = body.keyword;
						}
						if(body.color >= 0)
						{
							color = body.color;
						}
					}
					
					refreshPostList(null, keyword, color);
					break;
				}
				case PostNotification.UPDATE_POST:
				{
					//同步文章列表
					this.updatePostByLatestList(notification.getBody());
					this.updateTagPost(notification.getBody());
					break;
				}
				case PostNotification.DELETE_POST:
				{
					//同步文章列表
					this.deletePostByLatestList(notification.getBody());
					this.deleteTagPost(notification.getBody());
					break;
				}
				case PostNotification.ADD_POST:
				{
					//同步文章列表
					this.addPostByLatestList(notification.getBody());
					this.addTagPost(notification.getBody());
					break;
				}
				case SystemNotification.FULL_SCREEN:
				{
					//全屏
					if (notification.getBody())
					{
						_myPostsModule.currentState = "FullScreen";
						_myPostsModule.contentView.contentContainer.contentToolbar.currentState = "FullScreen";
					}
					else
					{
						_myPostsModule.currentState = "Normal";
						_myPostsModule.contentView.contentContainer.contentToolbar.currentState = "Normal";
					}
					break;
				}
			}
		}
		
		/**
		 * 获取文章
		 * 
		 */		
		public function getMorePosts(lastPost:Object):void
		{
			if(_hasMore)
			{
				this.refreshPostList(lastPost, _keyword, _color);
			}
		}
		
		/**
		 * 获取文章内容
		 * @param postId 文章ID
		 * 
		 */		
		public function getPostInfo(postId:Number):void
		{
			if(_token != null)
			{
				_token.removeEventListener(PostEvent.GET_POST_RESULT, getPostResultHandler);
				_token.removeEventListener(PostEvent.GET_POST_ERROR, getPostErrorHandler);
			}
			
			_token = _postProxy.getPostInfo(postId, _keyword);
			_token.addEventListener(PostEvent.GET_POST_RESULT, getPostResultHandler);
			_token.addEventListener(PostEvent.GET_POST_ERROR, getPostErrorHandler);
			_token.start();
		}
		
		/**
		 * 删除文章 
		 * @param post 文章信息
		 * 
		 */		
		public function removePostInfo(post:Object):void
		{
			var token:PostToken = _postProxy.remove(post);
			token.addEventListener(PostEvent.REMOVE_POST_RESULT, removePostResultHandler);
			token.addEventListener(PostEvent.REMOVE_POST_ERROR, removePostErrorHandler);
			token.start();
		}
		
		/**
		 * 获取标签文章列表返回 
		 * @param event	事件
		 * 
		 */		
		private function getTagPostsResultHandler(event:PostEvent):void
		{
			event.target.removeEventListener(PostEvent.GET_POSTS_RESULT, getTagPostsResultHandler);
			event.target.removeEventListener(PostEvent.GET_POSTS_ERROR, getTagPostsFaultHandler);
			
			if(event.posts == null)
			{
				_tagPostListState.tagPostsState[event.tag.id] = {more:false};
			}
			else
			{
				if (event.posts.length < PAGE_SIZE)
				{
					_tagPostListState.tagPostsState[event.tag.id] = {more:false};
				}
				else
				{
					_tagPostListState.tagPostsState[event.tag.id] = {more:true};
				}
				_sectionListDataProvider.addValues(event.posts, event.tag);
				_sectionListDataProvider.setSectionFlag(event.tag, true);
				_myPostsModule.postListView.liTagPost.reloadData();
			}
		}
		
		/**
		 * 获取标签文章列表失败 
		 * @param event 事件
		 * 
		 */		
		private function getTagPostsFaultHandler(event:PostEvent):void
		{
			event.target.removeEventListener(PostEvent.GET_POSTS_RESULT, getTagPostsResultHandler);
			event.target.removeEventListener(PostEvent.GET_POSTS_ERROR, getTagPostsFaultHandler);
		}
		
		/**
		 * 获取标签列表返回 
		 * @param event 事件
		 * 
		 */		
		private function getTagsResultHandler(event:PostEvent):void
		{
			event.target.removeEventListener(PostEvent.GET_TAGS_RESULT, getTagsResultHandler);
			event.target.removeEventListener(PostEvent.GET_TAGS_ERROR, getTagsErrorHandler);
			
			if(event.tags != null)
			{
				for(var i:int = 0; i < event.tags.length; i ++)
				{
					var tagInfo:Object = event.tags[i];
					_sectionListDataProvider.addSection(tagInfo);
				}
				_tagPostListState.hasMoreTags = event.tags.length == 30 ? true : false;
				_tagPostListState.pageNo = event.pageNo;
				_myPostsModule.postListView.liTagPost.dataProvider = _sectionListDataProvider;
			}
			else
			{
				_tagPostListState.hasMoreTags = false;
			}
		}
		
		/**
		 * 获取标签列表失败 
		 * @param event 事件
		 * 
		 */		
		private function getTagsErrorHandler(event:PostEvent):void
		{
			event.target.removeEventListener(PostEvent.GET_TAGS_RESULT, getTagsResultHandler);
			event.target.removeEventListener(PostEvent.GET_TAGS_ERROR, getTagsErrorHandler);
		}
		
		/**
		 * 获取文章返回
		 * @param event 事件
		 * 
		 */		
		private function getPostResultHandler(event:PostEvent):void
		{
			_token.removeEventListener(PostEvent.GET_POST_RESULT, getPostResultHandler);
			_token.removeEventListener(PostEvent.GET_POST_ERROR, getPostErrorHandler);
			
			var contentString:String = null;
			if(event.postInfo != null)
			{
				var tagString:String = "";
				var postInfo:Object = event.postInfo;
				
				if(postInfo.tags != null && postInfo.tags != "")
				{
					var tags:Array = postInfo.tags.split(";");
					for (var i:int = 0; i < tags.length; i++)
					{
						if(StringUtil.trim(tags[i]) != "")
						{
							tagString += "<span style='-moz-border-radius:2px;-webkit-border-radius:2px;border-radius:2px;display:block;float:left;padding:3px 5px 3px 5px;font-family:微软雅黑;background-color:#666666;color:white;font-size:11px;margin:0px 2px 10px 2px;' >" + tags[i] + "</span>";
						}
					}
					tagString = "<p>" + tagString + "</p>";
				}
				contentString = "<div style='margin:10px 10px 0px 10px;font-family:微软雅黑;font-size:14px;' >" + postInfo.title + "<div>" + tagString + "</div><hr style='clear:both;border:none;border-bottom:1px dashed #E1E1E1;' /></div><div style='margin:5px 10px 10px 10px;clear:both;font-family:Lantingqianhei;微软雅黑;'>" + postInfo.content + "</div>";
			}

			var htmlContentView:HTML = _myPostsModule.contentView.contentContainer.htmlContent;
			htmlContentView.htmlLoader.placeLoadStringContentInApplicationSandbox = true;
			htmlContentView.htmlText = contentString;
			
			if(event.attachments != null)
			{
				//显示附件列表
				_myPostsModule.contentView.currentState = "AttachPost";
				
				var attachments:Array = new Array();
				for (var j:int = 0; j < event.attachments.length; j++)
				{
					var attach:Object = event.attachments[j];
					if(attach.url != null)
					{
						var file:File = new File(attach.url);
						var attachInfo:AttachmentInfo = new AttachmentInfo(file);
						attachInfo.createTime = attach.createTime;
						attachments.push(attachInfo);
					}
				}
				
				_myPostsModule.contentView.gridAttachment.dataProvider = new ArrayCollection(attachments);
			}
			else
			{
				//隐藏附件列表
				_myPostsModule.contentView.currentState = "Normal";
			}
		}
		
		/**
		 * 获取文章错误 
		 * @param event 事件
		 * 
		 */		
		private function getPostErrorHandler(event:PostEvent):void
		{
			_token.removeEventListener(PostEvent.GET_POST_RESULT, getPostResultHandler);
			_token.removeEventListener(PostEvent.GET_POST_ERROR, getPostErrorHandler);
			
			_gnFacade.alert(event.error.message);
		}
		
		/**
		 * 刷新文章列表 
		 * 
		 * @param	lastPost	上一页最后一条文章记录
		 * @param	keyword		关键字
		 * @param	color		过滤颜色
		 */		
		private function refreshPostList(lastPost:Object = null, keyword:String = null, color:uint = 0xffffff):void
		{
			_keyword = keyword;
			_color = color;
			
			var token:PostToken = _postProxy.getLatestPosts(lastPost, PAGE_SIZE, keyword, color);
			token.addEventListener(PostEvent.GET_POSTS_RESULT, getPostsResultHandler);
			token.addEventListener(PostEvent.GET_POSTS_ERROR, getPostsErrorHandler);
			token.start();
		}
		
		/**
		 * 获取创建时间 
		 * @param date 时间
		 * @return 时间字符串
		 * 
		 */
		private function getCreateTimeString(date:Date):String
		{
			return date.getFullYear() + "-" + (date.getMonth() + 1) + "-" + date.getDate() + " " + date.getHours() + ":" + date.getMinutes() + ":" + date.getSeconds();
		}
		
		/**
		 * 删除文章返回 
		 * @param event 事件
		 * 
		 */		
		private function removePostResultHandler(event:PostEvent):void
		{
			event.target.removeEventListener(PostEvent.REMOVE_POST_RESULT, removePostResultHandler);
			event.target.removeEventListener(PostEvent.REMOVE_POST_ERROR, removePostErrorHandler);
			
			//清空内容面板
			_myPostsModule.contentView.contentContainer.htmlContent.htmlText = "";
			
			//派发删除文章通知
			var notif:PostNotification = new PostNotification(PostNotification.DELETE_POST, event.postInfo);
			_gnFacade.postNotification(notif);
		}
		
		/**
		 * 删除文章错误 
		 * @param event 事件
		 * 
		 */		
		private function removePostErrorHandler(event:PostEvent):void
		{
			event.target.removeEventListener(PostEvent.REMOVE_POST_RESULT, removePostResultHandler);
			event.target.removeEventListener(PostEvent.REMOVE_POST_ERROR, removePostErrorHandler);
			
			_gnFacade.alert("删除文章错误:" + event.error.details);
		}
		
		/**
		 * 列表项将要显示 
		 * @param event 事件
		 * 
		 */		
		private function itemWillDisplayHandler(event:SectionListEvent):void
		{
			var tagInfo:Object = _sectionListDataProvider.getSection(event.indexPath.section);
			var len:int = _sectionListDataProvider.getSectionDataLength(tagInfo);
			if (event.indexPath.row == len - 1)
			{
				var stateObj:Object = _tagPostListState.tagPostsState[tagInfo.id];
				if (stateObj.more)
				{
					stateObj.more = false;
					
					//加载数据
					var token:PostToken = _postProxy.getPostsByTag(tagInfo, _sectionListDataProvider.getValue(tagInfo, event.indexPath.row), PAGE_SIZE);
					token.addEventListener(PostEvent.GET_POSTS_RESULT, getTagPostsResultHandler);
					token.addEventListener(PostEvent.GET_POSTS_ERROR, getTagPostsFaultHandler);
					token.start();
				}
			}
		}
		
		/**
		 * 打开文章 
		 * @param event 事件
		 * 
		 */		
		private function postItemClickHandler(event:SectionListEvent):void
		{
			var postInfo:Object = _sectionListDataProvider.getValue(_sectionListDataProvider.getSection(event.indexPath.section),event.indexPath.row);
			this.getPostInfo(postInfo.id);
		}
		
		/**
		 * 小节将要显示 
		 * @param event 事件
		 * 
		 */		
		private function sectionWillDisplayHandler(event:SectionListEvent):void
		{
			if (event.section == _sectionListDataProvider.sectionCount - 1)
			{
				//加载更多小节
				if (_tagPostListState.hasMoreTags)
				{
					_tagPostListState.hasMoreTags = false;
					
					var token:PostToken = _postProxy.getTags(_tagPostListState.pageNo + 1);
					token.addEventListener(PostEvent.GET_TAGS_RESULT,getTagsResultHandler);
					token.addEventListener(PostEvent.GET_TAGS_ERROR, getTagsErrorHandler);
					token.start();
				}
			}
		}
		
		/**
		 * 更新文章信息到最近文章列表 
		 * @param postInfo 文章信息
		 * 
		 */		
		private function updatePostByLatestList(postInfo:Object):void
		{
			if (_postsList != null)
			{
				for (var i:int = 0; i < _postsList.length; i++)
				{
					var post:Object = _postsList[i];
					if (post.id == postInfo.id)
					{
						post.title = postInfo.title;
						post.modifyTime = postInfo.modifyTime;
						break;
					}
				}
				//刷新数据
				_myPostsModule.postListView.liPost.dataProvider = null;
				_myPostsModule.postListView.liPost.dataProvider = _postsList;
			}
		}
		
		/**
		 * 更新标签文章
		 * @param postInfo 文章信息
		 * 
		 */		
		private function updateTagPost(postInfo:Object):void
		{
			//刷新数据
			if (_sectionListDataProvider != null)
			{
				for (var i:int = 0; i < _sectionListDataProvider.sectionCount; i++)
				{
					var section:Object = _sectionListDataProvider.getSection(i);
					var count:int = _sectionListDataProvider.getSectionDataLength(section);
					for (var j:int = 0; j < count; j++)
					{
						var post:Object = _sectionListDataProvider.getValue(section, j);
						if (post.id == postInfo.id)
						{
							post.title = postInfo.title;
							post.modifyTime = postInfo.modifyTime;
						}
					}
				}
				this.module.postListView.liTagPost.reloadData();
			}
		}
		
		/**
		 * 删除最近文章列表文章 
		 * @param postInfo 文章信息
		 * 
		 */		
		private function deletePostByLatestList(postInfo:Object):void
		{
			if (_postsList != null)
			{
				for (var i:int = 0; i < _postsList.length; i++)
				{
					var post:Object = _postsList[i];
					if (post.id == postInfo.id)
					{
						_postsList.removeItemAt(i);
						break;
					}
				}
				//刷新数据
				_myPostsModule.postListView.liPost.dataProvider = _postsList;
			}
		}
		
		/**
		 * 删除标签文章 
		 * @param postInfo 文章信息
		 * 
		 */		
		private function deleteTagPost(postInfo:Object):void
		{
			if (_sectionListDataProvider != null)
			{
				for (var i:int = 0; i < _sectionListDataProvider.sectionCount; i++)
				{
					var section:Object = _sectionListDataProvider.getSection(i);
					var count:int = _sectionListDataProvider.getSectionDataLength(section);
					var j:int = 0;
					while (j < count)
					{
						var post:Object = _sectionListDataProvider.getValue(section, j);
						if (post.id == postInfo.id)
						{
							_sectionListDataProvider.removeValue(post, section);
							count--;
							continue;
						}
						j++;
					}
				}
				this.module.postListView.liTagPost.reloadData();
			}
		}
		
		/**
		 * 添加文章到最近列表 
		 * @param postInfo 文章信息
		 * 
		 */		
		private function addPostByLatestList(postInfo:Object):void
		{
			if(_postsList != null)
			{
				_postsList.addItemAt(postInfo, 0);
				this.module.postListView.liPost.dataProvider = _postsList;
			}
		}
		
		/**
		 * 添加标签文章 
		 * @param postInfo 文章信息
		 * 
		 */		
		private function addTagPost(postInfo:Object):void
		{
			if (_sectionListDataProvider != null)
			{
				if (postInfo.tags != null && postInfo.tags != "")
				{
					var tagArr:Array = (postInfo.tags as String).split(";");
					for (var i:int = 0; i < tagArr.length; i++)
					{
						var tagId:Number = _postProxy.getTagId(tagArr[i]);
						if (tagId == -1)
						{
							continue;
						}
						
						var tag:Object = new Object();
						tag.id = tagId;
						tag.name = tagArr[i];
						
						
						//检测是否已经加载的Section，如果已经加载则添加文章，否则只添加Section。
						if (_tagPostListState.tagPostsState[tagId] == null)
						{
							_sectionListDataProvider.addSection(tag);
						}
						else
						{
							_sectionListDataProvider.insertValue(postInfo, 0, tag);
						}
					}
				}
				else
				{
					//加入默认分组
					var defaultTag:Object = new Object();
					defaultTag.id = 0;
					defaultTag.name = "默认";
					
					_sectionListDataProvider.insertValue(postInfo, 0, defaultTag);
				}
				
				this.module.postListView.liTagPost.reloadData();
			}
		}
		
		/**
		 * 获取文章列表返回 
		 * @param event 事件对象
		 * 
		 */		
		private function getPostsResultHandler(event:PostEvent):void
		{
			event.target.removeEventListener(PostEvent.GET_POSTS_RESULT, getPostsResultHandler);
			event.target.removeEventListener(PostEvent.GET_POSTS_ERROR, getPostsErrorHandler);
			
			var listData:Array = event.posts;
			if(listData == null)
			{
				if (_reloadList)
				{
					_reloadList = false;
					_postsList.removeAll();
				}
				_myPostsModule.postListView.liPost.dataProvider = _postsList;
				_hasMore = false;
				return;
			}
			
			if(listData.length == PAGE_SIZE)
			{
				_hasMore = true;
			}
			else
			{
				_hasMore = false;
			}
			if (_reloadList)
			{
				_reloadList = false;
				_postsList.removeAll();
			}
			_postsList.addAll(new ArrayCollection(listData));
			_myPostsModule.postListView.liPost.dataProvider = _postsList;
		}
		
		/**
		 * 获取文章列表失败 
		 * @param event 事件对象
		 * 
		 */		
		private function getPostsErrorHandler(event:PostEvent):void
		{
			event.target.removeEventListener(PostEvent.GET_POSTS_RESULT, getPostsResultHandler);
			event.target.removeEventListener(PostEvent.GET_POSTS_ERROR, getPostsErrorHandler);
		}
	}
}